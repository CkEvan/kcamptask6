Objective:
1. Using Terraform, design and set up a Virtual Private Cloud (VPC) with both public and private subnets. Implement routing, security groups, and network access control lists (NACLs) to ensure proper communication and security within the VPC and an Ubuntu EC2 instance in each subnet. Work in the AWS EU-West-1 (Ireland) region.
2. Create separate child modules for your resources and reference them in your root module for readability and re-usability of your code.
3. Write a script to install Nginx on your EC2 instance in the public subnet on deployment
4. Write a script to install PostgreSQL on your EC2 instance in the public subnet on deployment
5. Clean up resource on completion using terraform destroy


STEP 1: Set Up The Environment
a. Make sure to download and install both terraform and AWS CLI
b. Create IAM user and generate access keys for that IAM user. 

STEP 2: Create the Project Directory
Create a directory for your Terraform project and navigate into it (kcamptask6)
"mkdir kcamptask6"
"cd kcamptask6"

STEP 3: 
Create a VPC:
Name: KCVPC
IPv4 CIDR block: 10.0.0.0/16
Script: kcvpc.tf
Image: task6_Images/kcvpcimage1.png

STEP 4: Subnets
Script: kcvpc.tf
Image: task6_Images/privatesubnet.png

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

STEP 5:  Internet Gateway (IGW)
Script: kcvpc.tf
Image: task6_Images/igw.png


STEP 6: Route Tables
Script: kcvpc.tf
Image: task6_Images/routetables.png

STEP 7: NAT Gateway
Script: kcvpc.tf
Image: task6_Images/NAT.png

STEP 8: Security Groups
Script: kcvpc.tf
Image: task6_Images/sgimage.png

STEP 9: Network ACLs
Script: kcvpc.tf
Image: task6_Images/nacls.png

# Deploy Instances
STEP 10: 