# here or env vars
provider "aws" {
  region     = "eu-west-1"
  access_key = "0123456789abcdefghil"
  secret_key = "0123456789abcdefghil0123456789abcdefghil"
}

# key name is under EC2 --> key pairs
variable "ec2_key_name" {
  description = "Desired name of AWS key pair"
  default="myawesomekeypair"
}

# CIDR of the VPC
variable "vpc_subnet" {
  description = "cidr assigned to VPC"
  default = "10.0.0.0/16"
}

# subnet for wireguard server
variable "wireguard_subnet" {
  default="10.0.1.0/24"
}

# ip of the internal client
variable "client_ip" {
  default="10.0.2.10"
}

# subnet for remote wireguard clients - used in route tables and security groups
variable "wg_client_subnet" {
  default="10.99.0.0/24"
}

# subnet for internal client
variable "private_subnet" {
  default="10.0.2.0/24"
}


variable "aws_region" {
  description = "AWS region to launch servers."
  default     = "eu-west-1"
}

# Ubuntu Precise 12.04 LTS (x64)
variable "aws_amis" {
  default = {
    eu-west-1 = "ami-674cbc1e"
    us-east-1 = "ami-1d4e7a66"
    us-west-1 = "ami-969ab1f6"
    us-west-2 = "ami-8803e0f0"
  }
}
