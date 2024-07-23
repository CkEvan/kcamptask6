variable "region" {
  default = "eu-west-1"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  default = "10.0.1.0/24"
}

variable "private_subnet_cidr" {
  default = "10.0.2.0/24"
}

variable "availability_zone" {
  default = "eu-west-1a"
}

provider "aws" {
  region = var.region
}

resource "aws_vpc" "KCVPC" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = "KCVPC"
  }
}

resource "aws_subnet" "PublicSubnet" {
  vpc_id            = aws_vpc.KCVPC.id
  cidr_block        = var.public_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "PrivateSubnet" {
  vpc_id            = aws_vpc.KCVPC.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = "PrivateSubnet"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.KCVPC.id
  tags = {
    Name = "InternetGateway"
  }
}

resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.KCVPC.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = {
    Name = "PublicRouteTable"
  }
}

resource "aws_route_table_association" "PublicSubnetAssociation" {
  subnet_id      = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.KCVPC.id
  tags = {
    Name = "PrivateRouteTable"
  }
}

resource "aws_route_table_association" "PrivateSubnetAssociation" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

resource "aws_eip" "NAT" {
  domain = "vpc"
}


resource "aws_nat_gateway" "NAT" {
  allocation_id = aws_eip.NAT.id
  subnet_id     = aws_subnet.PublicSubnet.id
  tags = {
    Name = "NatGateway"
  }
}

resource "aws_route" "PrivateSubnetRoute" {
  route_table_id         = aws_route_table.PrivateRouteTable.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.NAT.id
}

resource "aws_security_group" "PublicSG" {
  vpc_id = aws_vpc.KCVPC.id
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["102.88.70.158/32"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PublicSecurityGroup"
  }
}

resource "aws_security_group" "PrivateSG" {
  vpc_id = aws_vpc.KCVPC.id
  ingress {
    from_port   = 5432
    to_port     = 5432
    protocol    = "tcp"
    cidr_blocks = [aws_subnet.PublicSubnet.cidr_block]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "PrivateSecurityGroup"
  }
}

resource "aws_network_acl" "PublicNACL" {
  vpc_id = aws_vpc.KCVPC.id
  tags = {
    Name = "PublicNACL"
  }
}

resource "aws_network_acl_rule" "PublicNACLInboundHTTP" {
  network_acl_id = aws_network_acl.PublicNACL.id
  rule_number    = 100
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 80
  to_port        = 80
}

resource "aws_network_acl_rule" "PublicNACLInboundHTTPS" {
  network_acl_id = aws_network_acl.PublicNACL.id
  rule_number    = 101
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 443
  to_port        = 443
}

resource "aws_network_acl_rule" "PublicNACLInboundSSH" {
  network_acl_id = aws_network_acl.PublicNACL.id
  rule_number    = 102
  egress         = false
  protocol       = "tcp"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = 22
  to_port        = 22
}

resource "aws_network_acl_rule" "PublicNACLOutbound" {
  network_acl_id = aws_network_acl.PublicNACL.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}

resource "aws_network_acl" "PrivateNACL" {
  vpc_id = aws_vpc.KCVPC.id
  tags = {
    Name = "PrivateNACL"
  }
}

resource "aws_network_acl_rule" "PrivateNACLInbound" {
  network_acl_id = aws_network_acl.PrivateNACL.id
  rule_number    = 100
  egress         = false
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = aws_subnet.PublicSubnet.cidr_block
}

resource "aws_network_acl_rule" "PrivateNACLOutbound" {
  network_acl_id = aws_network_acl.PrivateNACL.id
  rule_number    = 100
  egress         = true
  protocol       = "-1"
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
}
