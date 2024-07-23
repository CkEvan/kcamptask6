# Objective

Design and set up a Virtual Private Cloud (VPC) using Terraform with public and private subnets. 
Implement routing, security groups, and network access control lists (NACLs) to ensure proper communication and security within the VPC. Deploy an Ubuntu EC2 instance in each subnet in the AWS EU-West-1 (Ireland) region. 
Create separate child modules for resources and reference them in the root module for readability and re-usability of the code. 
Write a script to install Nginx on the EC2 instance in the public subnet on deployment. 
Write a script to install PostgreSQL on the EC2 instance in the public subnet on deployment. 
Clean up resources on completion using `terraform destroy`.


# Prerequisites
- Download and install Terraform.
- Download and install the AWS CLI.
- Create an IAM user and generate access keys for that IAM user.
  

## STEP 1: Set Up The Environment

- Ensure Terraform and AWS CLI are installed.
- Configure AWS CLI with IAM user credentials:
   aws configure


## STEP 2: Create the Project Directory
Create a directory for your Terraform project and navigate into it (kcamptask6):

```
mkdir kcamptask6
cd kcamptask6
```

## STEP 3: Create a VPC

```
resource "aws_vpc" "KCVPC" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "KCVPC"
  }
}
```

Script: https://github.com/CkEvan/kcamptask6/blob/d6aec266c071851ca517733f5cd228e2a52a02fa/kcvpc.tf

![image](https://github.com/user-attachments/assets/26999743-92b3-4d68-933f-d26fd747935e)



## STEP 4: Subnets
Script: https://github.com/CkEvan/kcamptask6/blob/d6aec266c071851ca517733f5cd228e2a52a02fa/kcvpc.tf

```
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
```

![image](https://github.com/user-attachments/assets/d364fd1b-1faa-48f6-aee7-c991b78a2673)



## STEP 5: Internet Gateway (IGW)
- Script: `kcvpc.tf`


```  
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.KCVPC.id
  tags = {
    Name = "InternetGateway"
  }
}
```

![image](https://github.com/user-attachments/assets/ddf2b231-9bac-4c1e-b421-8c18fd07620a)



## STEP 6: Route Tables
- Script: `kcvpc.tf`

```
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
```

![image](https://github.com/user-attachments/assets/fc1c388d-819b-465e-bb83-7d8bb00889df)



## STEP 7: NAT Gateway
- Script: `kcvpc.tf`

```
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
```

![image](https://github.com/user-attachments/assets/724164d0-e7f7-453f-aad0-6c0d7ce339dd)



## STEP 8: Security Groups
- Script: `kcvpc.tf`

```
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
```

![image](https://github.com/user-attachments/assets/e94cd797-e29d-434d-bf40-d8c2c779cc81)



## STEP 9: Network ACLs
- Script: `kcvpc.tf`

```
resource "aws_network_acl" "PublicNACL" {
  vpc_id = aws_vpc.KCVPC.id
  tags = {
    Name = "PublicNACL"
  }
}
```

![image](https://github.com/user-attachments/assets/bdb2a6cb-62d0-4455-acca-8b7958cfeb81)



## STEP 10: Deploy 2 EC2 Instances on Each Subnet
- Script: `kcec2.tf`

```
resource "aws_instance" "PublicInstance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PublicSubnet.id
  tags = {
    Name = "PublicInstance"
  }
}

resource "aws_instance" "PrivateInstance" {
  ami           = var.ami_id
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.PrivateSubnet.id
  tags = {
    Name = "PrivateInstance"
  }
}
```

![image](https://github.com/user-attachments/assets/afa4bee4-adc8-404e-9a5f-4d6a1a916da9)



## STEP 11: Script to Install Nginx on EC2 Instance in the Public Subnet on Deployment
- Script: [kcec2.tf](kcec2.tf)

```
#!/bin/bash
sudo apt-get update
sudo apt-get install -y nginx
```


## STEP 12: Script to Install PostgreSQL on EC2 Instance in the Public Subnet on Deployment
- Script: [kcec2.tf](kcec2.tf)

```
#!/bin/bash
sudo apt-get update
sudo apt-get install -y PostgreSQL
```

![image](https://github.com/user-attachments/assets/5962029a-bd65-4d05-bafa-4dd4ae35ff9f)

![image](https://github.com/user-attachments/assets/778ffc0e-d4a1-498e-883e-f42e260bb2e6)




## Cleanup

```
terraform destroy 
```

![image](https://github.com/user-attachments/assets/f7ce1265-f84f-4686-ba3d-8674b3aba305)

![image](https://github.com/user-attachments/assets/04912913-a6d1-4fa4-809c-0b4009c74736)


NOTE: Please this documentation contains a snippet of the main script and screenshots of the activities on this task, to view the entire script please refer to the first script at https://github.com/CkEvan/kcamptask6/blob/d6aec266c071851ca517733f5cd228e2a52a02fa/kcvpc.tf and second script at https://github.com/CkEvan/kcamptask6/blob/d6aec266c071851ca517733f5cd228e2a52a02fa/kcec2.tf . As for the images please check https://github.com/CkEvan/kcamptask6/tree/d6aec266c071851ca517733f5cd228e2a52a02fa/task6_Images

Thank you. 

