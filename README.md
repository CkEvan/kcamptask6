# Terraform Task

1. Using Terraform, design and set up a Virtual Private Cloud (VPC) with public and private subnets. Implement routing, security groups, and network access control lists (NACLs) to ensure proper communication and security within the VPC and an Ubuntu EC2 instance in each subnet. Work in the AWS EU-West-1 (Ireland) region.
2. Create separate child modules for your resources and reference them in your root module for readability and re-usability of your code.
3. Write a script to install Nginx on your EC2 instance in the public subnet on deployment
4. Write a script to install PostgreSQL on your EC2 instance in the public subnet on deployment
5. Clean up resources on completion using terraform destroy


# Prerequisites
```
- Download and install Terraform.
- Download and install the AWS CLI.
- Create an IAM user and generate access keys for that IAM user.
 ``` 

## STEP 1: Set Up The Environment

- Ensure Terraform and AWS CLI are installed.
- Configure AWS CLI with IAM user credentials:
```
   aws configure  
```
![image](https://github.com/user-attachments/assets/23098b57-e757-4b20-99e0-a2592a14b6b7)


## STEP 2: Create the Project Directory
Create a directory for your Terraform project and navigate into it (kcamptask6):

```
mkdir kcamptask6
cd kcamptask6
```

## STEP 3: Create a VPC

```
VPC Name: KCVPC
IPv4 CIDR block: 10.0.0.0/16
```
![image](https://github.com/user-attachments/assets/f147894f-b22a-411c-89f1-0db0af70f0f7)


![image](https://github.com/user-attachments/assets/26999743-92b3-4d68-933f-d26fd747935e)



## STEP 4: Subnets
Create a Pulic Subnet with IPv4 (10.0.1.0/24)
Create Private Subnet using IPv4 (10.0.2.0/24)
Select any AZ from your region
Select any AZ from your region (preferably the same as the Public Subnet for simplicity)

```
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
```

![image](https://github.com/user-attachments/assets/d364fd1b-1faa-48f6-aee7-c991b78a2673)



## STEP 5: Internet Gateway (IGW)
Create and attach an IGW to KCVPC.

```  
resource "aws_internet_gateway" "IGW" {
  vpc_id = aws_vpc.KCVPC.id

  tags = {
    Name = "IGW"
  }
}
```

![image](https://github.com/user-attachments/assets/ddf2b231-9bac-4c1e-b421-8c18fd07620a)



## STEP 6: Route Tables
Create Public and Private Route Tables
Associate PublicSubnet with Public route table
Associate PrivateSubnet with Private route table.
Ensure no direct route to the internet.

```
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

resource "aws_route_table_association" "PublicSubnetRouteTable" {
  subnet_id      = aws_subnet.PublicSubnet.id
  route_table_id = aws_route_table.PublicRouteTable.id
}

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

resource "aws_route_table_association" "PrivateSubnetRouteTable" {
  subnet_id      = aws_subnet.PrivateSubnet.id
  route_table_id = aws_route_table.PrivateRouteTable.id
}

```

![image](https://github.com/user-attachments/assets/fc1c388d-819b-465e-bb83-7d8bb00889df)



## STEP 7: NAT Gateway
Create a NAT Gateway in the PublicSubnet.
Allocate an Elastic IP for the NAT Gateway.
Update the PrivateRouteTable to route internet traffic (0.0.0.0/0) to the NAT Gateway.

```
resource "aws_eip" "NAT_eip" {
  domain   = "vpc"
}

resource "aws_nat_gateway" "NAT_IGW" {
  allocation_id = aws_eip.NAT_eip.id
  subnet_id     = aws_subnet.PublicSubnet.id
  connectivity_type = "public"
  tags = {
    Name = "NAT_IGW"
  }
}
```

![image](https://github.com/user-attachments/assets/724164d0-e7f7-453f-aad0-6c0d7ce339dd)
![image](https://github.com/user-attachments/assets/77bae851-cc24-4459-bfae-67b79c64bc6f)



## STEP 8: Security Groups
Create a Security Group for public instances 
Allow inbound HTTP (port 80) and HTTPS (port 443) traffic from anywhere (0.0.0.0/0).
Allow inbound SSH (port 22) traffic from a specific IP 
Allow all outbound traffic.
Create a Security Group for private instances 
Allow inbound traffic from the PublicSubnet on required ports 
Allow all outbound traffic.

```
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
```
![image](https://github.com/user-attachments/assets/86c056e6-d801-4303-8ea7-f7f13ac8050c)





## STEP 9: Network ACLs
Configure NACLs for additional security on both subnets.
Public Subnet NACL: Allow inbound HTTP, HTTPS, and SSH traffic. Allow outbound traffic.
Private Subnet NACL: Allow inbound traffic from the public subnet. Allow outbound traffic to the public subnet and internet.

```
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

resource "aws_network_acl_association" "NACL_PublicAssociate" {
  network_acl_id = aws_network_acl.NACL_Public.id
  subnet_id      = aws_subnet.PublicSubnet.id
}

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

resource "aws_network_acl_association" "NACL_PrivateAssociate" {
  network_acl_id = aws_network_acl.NACL_Private.id
  subnet_id      = aws_subnet.PrivateSubnet.id
}
```
Creating Local SSH-KEY
```
resource "aws_key_pair" "task6sshkey" {
  key_name   = "task6sshkey"
  public_key = file("task6sshkey.pub")
}
```

![image](https://github.com/user-attachments/assets/bdb2a6cb-62d0-4455-acca-8b7958cfeb81)



## STEP 10: Deploy 2 EC2 Instances on Each Subnet
Launch an EC2 instance in the PublicSubnet:
Use the public security group.
Verify that the instance can be accessed via the internet.
Launch an EC2 instance in the PrivateSubnet:
Use the private security group.
Verify that the instance can access the internet through the NAT Gateway and can communicate with the public instance.

```
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

```

![image](https://github.com/user-attachments/assets/e3cd998a-f1f4-4a80-bf59-3b60e16b7ecd)



## STEP 13: Terraform Commands
```
terraform init 
terraform validate
terraform plan 
terraform apply 
```
![image](https://github.com/user-attachments/assets/7c3e7187-e594-4022-9d3f-3469ecc9a88b)



![image](https://github.com/user-attachments/assets/0e83e137-d8ee-4774-9f02-e6da04d46c02)


![image](https://github.com/user-attachments/assets/778ffc0e-d4a1-498e-883e-f42e260bb2e6)




## Cleanup

```
terraform destroy 
```

![image](https://github.com/user-attachments/assets/f7ce1265-f84f-4686-ba3d-8674b3aba305)

![image](https://github.com/user-attachments/assets/04912913-a6d1-4fa4-809c-0b4009c74736)


Attached: 
terraform.tf
modules
script
output.tf
variables
task6_images
![image](https://github.com/user-attachments/assets/dfb47091-679c-4df9-9968-06eb88d16c66)
![image](https://github.com/user-attachments/assets/5d204005-2d0c-4447-9872-fb769f830d94)
![image](https://github.com/user-attachments/assets/4656e5e2-f950-429d-bac5-cc7bc92e62b4)


Thank you. 

