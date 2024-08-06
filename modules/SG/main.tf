resource "aws_security_group" "this" {
  vpc_id = var.vpc_id
  tags = {
    Name = var.name
  }
}

resource "aws_security_group_rule" "ingress" {
  for_each = { for rule in var.ingress : rule.from_port => rule }
  type = "ingress"
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
  security_group_id = aws_security_group.this.id
}

resource "aws_security_group_rule" "egress" {
  for_each = { for rule in var.egress : rule.from_port => rule }
  type = "egress"
  from_port = each.value.from_port
  to_port = each.value.to_port
  protocol = each.value.protocol
  cidr_blocks = each.value.cidr_blocks
  security_group_id = aws_security_group.this.id
}

output "security_group_id" {
  value = aws_security_group.this.id
}