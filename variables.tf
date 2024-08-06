variable "region" {
  description = "AWS region"
  default = "eu-west-1"
}

variable "vpc_cidr_block" {
  description = "CIDR block for the VPC"
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr_block" {
  description = "CIDR block for the public subnet"
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr_block" {
  description = "CIDR block for the private subnet"
  default = "10.0.2.0/24"
}

variable "availability_zone" {
  description = "Availability zone"
  default = "eu-west-1a"
}

variable "instance_type" {
  description = "EC2 instance type"
  default = "t2.micro"
}

variable "ami" {
  description = "AMI ID"
  default = "ami-0c38b837cd80f13bb"
}

variable "key_name" {
  description = "Name of the SSH key pair"
  default = "task6sshkey"
}

variable "public_key_path" {
  description = "Path to the public key file"
  default = "task6sshkey.pub"
}

variable "public_instance_user_data" {
  description = "User data script for the public instance"
  default = "scripts/install_nginx.sh"
}

variable "private_instance_user_data" {
  description = "User data script for the private instance"
  default = "scripts/install_postgresql.sh"
}