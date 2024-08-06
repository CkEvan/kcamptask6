variable "ami" {
  description = "AMI ID for the instance"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "key_name" {
  description = "Name of the key pair"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_group_ids" {
  description = "List of security group IDs"
  type        = list(string)
}

variable "availability_zone" {
  description = "Availability zone for the instance"
  type        = string
}

variable "name" {
  description = "Name of the instance"
  type        = string
}

variable "description" {
  description = "Description of the instance"
  type        = string
}

variable "user_data" {
  description = "User data script"
  type        = string
}