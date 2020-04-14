# CREATE VPC
#https://www.terraform.io/docs/providers/aws/r/vpc.html

resource "aws_vpc" "default" {
  cidr_block = var.vpc_subnet
  tags = {
    Name = "wireguard"
    }
}

# CREATE SUBNETS
# https://www.terraform.io/docs/providers/aws/r/subnet.html
# two subnets will be created, one for wireguard server, one for clients

# public subnet for wireguard
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.wireguard_subnet
  map_public_ip_on_launch = true
  tags = {
    Name = "wireguard"
  }
}

# private subnet for internal instances
resource "aws_subnet" "private" {
  vpc_id                  = aws_vpc.default.id
  cidr_block              = var.private_subnet
  map_public_ip_on_launch = false
  tags = {
    Name = "private"
  }
}

# SECURITY GROUPS
# https://www.terraform.io/docs/providers/aws/r/security_group.html

# security group for wireguard inbound traffic
resource "aws_security_group" "wireguard" {
  tags = {
    Name = "allow_wireguard"
  }
  description = "traffic to wireguard"
  vpc_id      = aws_vpc.default.id

  # access to wireguard service
  ingress {
    from_port   = 51820
    to_port     = 51820
    protocol    = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # inbound ssh
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  # outbound internet access
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# security group for client
resource "aws_security_group" "client" {
  tags = {
    Name = "allow_client"
  }
  description = "traffic to client"
  vpc_id      = aws_vpc.default.id

  # permit traffic from wireguard subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.wireguard_subnet]
  }

  # permit traffic from wireguard clients subnet
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.wg_client_subnet]
  }

  # permit outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# EC2 INSTANCES
# https://www.terraform.io/docs/providers/aws/r/instance.html

# wireguard server
resource "aws_instance" "wireguard" {
  tags = {
    Name = "wireguard"
  }

  # instance type
  instance_type = "t2.micro"
  ami = lookup(var.aws_amis, var.aws_region)

  # disable check to permit ip forward
  source_dest_check = false

  # assign key pair to instance
  key_name = var.ec2_key_name

  # assing security group to instance
  vpc_security_group_ids = [aws_security_group.wireguard.id]

  # assign instance to subnet
  subnet_id = aws_subnet.public.id
}

# client instance, will be reachable via wireguard
resource "aws_instance" "client" {

  tags = {
    Name = "client"
  }

  # instance type
  instance_type = "t2.micro"
  ami = lookup(var.aws_amis, var.aws_region)

  # assign key pair to instance
  key_name = var.ec2_key_name

  # assing security group to instance
  vpc_security_group_ids = [aws_security_group.client.id]

  # assign subnet to instance
  subnet_id = aws_subnet.private.id

  # assign private IP to the instance
  private_ip = var.client_ip
}

# route table
# https://www.terraform.io/docs/providers/aws/r/route_table.html

resource "aws_route_table" "to_wireguard" {
  vpc_id = aws_vpc.default.id
  tags = {
    Name = "to_wireguard"
  }
}

# default route of private instance goes to wireguard server
resource "aws_route" "to_wireguard" {
  route_table_id = aws_route_table.to_wireguard.id
  destination_cidr_block = var.wg_client_subnet
  instance_id = aws_instance.wireguard.id
}

# ASSOCIATE ROUTE TABLE TO SUBNET
# https://www.terraform.io/docs/providers/aws/r/route_table_association.html

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.to_wireguard.id
}

# DEFAULT ROUTE TABLE FOR VPC

# create igw
resource "aws_internet_gateway" "default" {
  vpc_id = aws_vpc.default.id
}

# Grant the VPC internet access on its main route table
resource "aws_route" "internet_access" {
  route_table_id         = aws_vpc.default.main_route_table_id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.default.id
}
