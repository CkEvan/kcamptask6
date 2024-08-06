variable "ami" {
  description = "AMI ID"
  type        = string
}

variable "instance_type" {
  description = "Instance type"
  type        = string
}

variable "key_name" {
  description = "Key pair name"
  type        = string
}

variable "subnet_id" {
  description = "Subnet ID"
  type        = string
}

variable "security_groups" {
  description = "Security groups"
  type        = list(string)
}

variable "availability_zone" {
  description = "Availability zone"
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