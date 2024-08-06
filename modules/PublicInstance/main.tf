resource "aws_instance" "this" {
  ami                    = var.ami
  instance_type          = var.instance_type
  key_name               = var.key_name
  subnet_id              = var.subnet_id
  security_groups        = var.security_groups
  availability_zone      = var.availability_zone
  associate_public_ip_address = true

  root_block_device {
    volume_type          = "gp3"
    volume_size          = 20
    delete_on_termination = true
  }

  tags = {
    Name        = var.name
    Description = var.description
  }

  user_data = var.user_data
}