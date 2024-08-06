variable "vpc_id" {
  description = "VPC ID"
}

variable "cidr_block" {
  description = "CIDR block for the subnet"
}

variable "availability_zone" {
  description = "Availability zone"
}

variable "map_public_ip_on_launch" {
  description = "Should instances in this subnet be assigned a public IP address"
}

variable "name" {
  description = "Name of the subnet"
}