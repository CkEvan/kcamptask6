# Deploy EC2 Instances in each subnet

variable "ami_id" {
  default = "ami-0c38b837cd80f13bb"  # Replace this with the correct AMI ID
}

variable "instance_type" {
  description = "The type of instance to start"
  type        = string
  default     = "t2.micro"
}

resource "aws_instance" "public_instance" {
  ami           = var.ami_id
  instance_type = "t2.micro"  # Fixed: enclosed in quotes
  subnet_id     = aws_subnet.PublicSubnet.id
  vpc_security_group_ids = [aws_security_group.PublicSG.id]
  tags = {
    Name = "PublicInstance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install nginx -y
              EOF
}

resource "aws_instance" "private_instance" {
  ami           = var.ami_id
  instance_type = var.instance_type  # Correctly referencing the variable
  subnet_id     = aws_subnet.PrivateSubnet.id
  vpc_security_group_ids = [aws_security_group.PrivateSG.id]
  tags = {
    Name = "PrivateInstance"
  }

  user_data = <<-EOF
              #!/bin/bash
              sudo apt update -y
              sudo apt install postgresql postgresql-contrib -y
              EOF
}
