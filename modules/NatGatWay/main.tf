resource "aws_eip" "this" {
  domain = "vpc"
}

resource "aws_nat_gateway" "this" {
  subnet_id = var.subnet_id
  allocation_id = aws_eip.this.id
  connectivity_type = "public"
  tags = {
    Name = "NAT_GW"
  }
}

output "nat_gateway_id" {
  value = aws_nat_gateway.this.id
}