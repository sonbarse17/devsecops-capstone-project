provider "aws" {
  region = "us-east-1"
  # Insecure: Using access keys directly or lacking role assumptions could be defined here
}

# Insecure Subnets & VPC - Public only
resource "aws_vpc" "insecure_vpc" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support = true
  enable_dns_hostnames = true
  
  tags = {
    Name = "insecure-aws-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id     = aws_vpc.insecure_vpc.id
  cidr_block = "10.0.1.0/24"
  map_public_ip_on_launch = true # Insecure: Default public IPs
  availability_zone = "us-east-1a"
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id     = aws_vpc.insecure_vpc.id
  cidr_block = "10.0.2.0/24"
  map_public_ip_on_launch = true
  availability_zone = "us-east-1b"
}

# Insecure Security Group: Allow all ingress traffic everywhere
resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Allow all inbound traffic"
  vpc_id      = aws_vpc.insecure_vpc.id

  # Insecure: allow all ports from anywhere
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Insecure EKS Cluster implementation
resource "aws_eks_cluster" "insecure_eks" {
  name     = "insecure-cluster"
  role_arn = "arn:aws:iam::123456789012:role/FakeAdminRole" # Example placeholder

  vpc_config {
    subnet_ids = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    endpoint_public_access = true # INSECURE: Public API endpoint, no CIDR restriction
    endpoint_private_access = false
  }
}
