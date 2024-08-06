variable "cidr_block" {
  description = "The CIDR block for the VPC"
  type        = string
}
variable "vpc_id" {
  description = "The ID of the VPC to attach the Internet Gateway to."
  type        = string
}