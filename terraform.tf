# Configure the AWS Provider
provider "aws" {
  region = "eu-west-1"
}

# Create a VPC
resource "aws_vpc" "KCVPC" {
  cidr_block = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames             = true
  assign_generated_ipv6_cidr_block = false
  tags = {
    Name = "KCVPC"
  }
}

# Creating Subnets:
resource "aws_subnet" "PublicSubnet" {
  vpc_id     = aws_vpc.KCVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "PublicSubnet"
  }
}

resource "aws_subnet" "PrivateSubnet" {
  vpc_id     = aws_vpc.KCVPC.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "eu-west-1a"
  map_public_ip_on_launch = false
   tags = {
    Name = "PrivateSubnet"
  }
}

# Configure an Internet Gateway (IGW):
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.KCVPC.id

  tags = {
    Name = "IGW"
  }
}

# Configure Route Tables:
resource "aws_route_table" "PublicRouteTable" {
  vpc_id = aws_vpc.KCVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.IGW.id
  }

  tags = {
    Name = "PublicRouteTable"
  }
}

# Associate PublicSubnet with this route table:
resource "aws_route_table_association" "PublicSubnetRouteTable" {
  subnet_id      = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

# Private Route Table:
resource "aws_route_table" "PrivateRouteTable" {
  vpc_id = aws_vpc.KCVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.NAT_IGW.id
  }

  tags = {
    Name = "PrivateRouteTable"
  }
}

# Associate PrivateSubnet with this route table:
resource "aws_route_table_association" "PrivateSubnetRouteTable" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

# Allocate an Elastic IP for the NAT Gateway:
resource "aws_eip" "NAT_eip" {
  domain   = "vpc"
}


# Configure NAT Gateway:
resource "aws_nat_gateway" "NAT_IGW" {
  allocation_id = aws_eip.NAT_eip.id
  subnet_id     = aws_subnet.PublicSubnet.id
  connectivity_type = "public"
  tags = {
    Name = "NAT_IGW"
  }
}

# Create a Security Group for public instances: 
resource "aws_security_group" "PublicSG" {
  vpc_id      = aws_vpc.KCVPC.id

  tags = {
    Name = "PublicSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "https" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_ingress_rule" "http" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "ssh" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "102.89.33.223/32"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"  
  from_port         = 0
  to_port           = 0
}




# Create a Security Group for private instances: 
resource "aws_security_group" "PrivateSG" {
  vpc_id      = aws_vpc.KCVPC.id

  tags = {
    Name = "PrivateSG"
  }
}

resource "aws_vpc_security_group_ingress_rule" "PostgreSQL" {
  security_group_id = aws_security_group.PublicSG.id
  cidr_ipv4         = "10.0.1.0/24"
  from_port         = 5432
  ip_protocol       = "tcp"
  to_port           = 5432
}

resource "aws_vpc_security_group_egress_rule" "allow_all_traffic" {
  security_group_id = aws_security_group.PrivateSG.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1" 
  from_port         = 0
  to_port           = 0
}  


# Configure NACLs for additional security on both subnets:
# NACL for Public Subnet
resource "aws_network_acl" "NACL_Public" {
  vpc_id = aws_vpc.KCVPC.id

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 80
    to_port    = 80
  }

ingress {
    protocol   = "tcp"
    rule_no    = 101
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 443
    to_port    = 443
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 102
    action     = "allow"
    cidr_block = "102.89.33.223/32"
    from_port  = 22
    to_port    = 22
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "NACL_Public"
  }
}

# Public Subnet NACL: 
resource "aws_network_acl_association" "NACL_PublicAssociate" {
  network_acl_id = aws_network_acl.NACL_Public.id
  subnet_id      = aws_subnet.PublicSubnet.id
}


# NACL for Private Subnet
resource "aws_network_acl" "NACL_Private" {
  vpc_id = aws_vpc.KCVPC.id

  ingress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = -1
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.1.0/24"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "NACL_Private"
  }
}

# Private Subnet NACL:
resource "aws_network_acl_association" "NACL_PrivateAssociate" {
  network_acl_id = aws_network_acl.NACL_Private.id
  subnet_id      = aws_subnet.PrivateSubnet.id
}

# Generating ssh-key locally 
resource "aws_key_pair" "task6sshkey" {
  key_name   = "task6sshkey"
  public_key = file("task6sshkey.pub")
}

# Launch an EC2 instance in the PublicSubnet:
resource "aws_instance" "Public_Instance" {
  ami               = "ami-0c38b837cd80f13bb"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-1a"
  key_name          = aws_key_pair.task6sshkey.id
  subnet_id         = aws_subnet.PublicSubnet.id
  security_groups   = aws_security_group.PublicSG.id
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name = "Public_Instance"
    description = "webserver"
  }

user_data = <<-EOF
                #!/bin/bash

                #installing nginx webserver 
                sudo apt update -y
                sudo apt install nginx -y
                sudo systemctl start nginx -y
                sudo systemctl enable nginx

                #install postgresql-client
                sudo apt update -y
                sudo apt install postgresql-client -y
                  
                EOF
}


# Launch an EC2 instance in the PrivateSubnet:
resource "aws_instance" "Private_Instance" {
  ami               = "ami-0c38b837cd80f13bb"
  instance_type     = "t2.micro"
  availability_zone = "eu-west-1a"
  key_name          = aws_key_pair.task6sshkey.id
  subnet_id         = aws_subnet.PrivateSubnet.id
  security_groups   = aws_security_group.PrivateSG.id
  associate_public_ip_address = true

  root_block_device {
    volume_type           = "gp3"
    volume_size           = 20
    delete_on_termination = true
  }

  tags = {
    Name = "Private_Instance"
    description = "database"
  }
  user_data = <<-EOF
                #!/bin/bash
                sudo apt-get update -y
                sudo apt-get install -y postgresql postgresql-contrib
                sudo systemctl start postgresql
                sudo systemctl enable postgresql
                sudo -u postgres psql -c "CREATE USER admin WITH PASSWORD 'kcec2@123#';"
                sudo -u postgres psql -c "CREATE DATABASE kcdata OWNER admin;"
                sudo -u postgres psql -c "GRANT ALL PRIVILEGES ON DATABASE kcdata TO admin;"
                sudo sed -i "s/#listen_addresses = 'localhost'/listen_addresses = '*'/" /etc/postgresql/*/main/postgresql.conf
                echo "host    all             all             0.0.0.0/0               md5" | sudo tee -a /etc/postgresql/*/main/pg_hba.conf
                sudo systemctl restart postgresql
                sudo ufw allow 5432/tcp
                EOF
}
