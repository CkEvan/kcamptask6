resource "aws_route_table" "this" {
  vpc_id = var.vpc_id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = var.gateway_id
  }
  tags = {
    Name = var.name
  }
}

resource "aws_route_table_association" "this" {
  subnet_id = var.subnet_id
  route_table_id = aws_route_table.this.id
}

output "route_table_id" {
  value = aws_route_table.this.id
}