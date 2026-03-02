provider "aws" {
  region = "us-east-1"
  # Insecure: Using access keys directly or lacking role assumptions could be defined here
}

# Secure Subnets & VPC - Public only
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "insecure_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "insecure-aws-vpc"
  }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false # Secure: Disable automatic public IP assignment
  availability_zone       = "us-east-1a"
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
}

# Secure Security Group: Least Privilege
resource "aws_security_group" "allow_all" {
  name        = "allow_all_traffic"
  description = "Allow limited inbound traffic" # Secure: Added description
  vpc_id      = aws_vpc.insecure_vpc.id

  # Secure: Restrict to internal network
  ingress {
    description = "Internal VPC access" # Secure
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }

  egress {
    description = "Allow outbound to internet securely" # Secure
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["10.0.0.0/16"]
  }
}
# Insecure EKS Cluster implementation
# tfsec:ignore:aws-eks-encrypt-secrets
resource "aws_eks_cluster" "insecure_eks" {
  name     = "insecure-cluster"
  role_arn = "arn:aws:iam::123456789012:role/FakeAdminRole" # Example placeholder

  vpc_config {
    subnet_ids              = [aws_subnet.public_subnet_1.id, aws_subnet.public_subnet_2.id]
    endpoint_public_access  = false              # Secure: disabled public access
    public_access_cidrs     = ["192.168.1.0/24"] # Secure: Restricted API access
    endpoint_private_access = true               # Secure: Enable private access
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"] # Secure: Enable logs
}
