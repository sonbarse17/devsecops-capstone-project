provider "aws" {
  region = "us-east-1"
  # Insecure: Using access keys directly or lacking role assumptions could be defined here
}

# Secure Subnets & VPC (3-Tier Architecture)
# tfsec:ignore:aws-ec2-require-vpc-flow-logs-for-all-vpcs
resource "aws_vpc" "insecure_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "devsecops-vpc" }
}

# --- 1. Public Tier ---
resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags                    = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags                    = { Name = "public-subnet-2" }
}

# --- 2. App Tier (EKS) ---
resource "aws_subnet" "app_subnet_1" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags                    = { Name = "app-subnet-1" }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags                    = { Name = "app-subnet-2" }
}

# --- 3. Data Tier (DBs) ---
resource "aws_subnet" "data_subnet_1" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.5.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags                    = { Name = "data-subnet-1" }
}

resource "aws_subnet" "data_subnet_2" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "10.0.6.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags                    = { Name = "data-subnet-2" }
}

# -------------------------------------------------------------
# Security Groups (Microsegmentation)
# -------------------------------------------------------------

resource "aws_security_group" "public_sg" {
  name        = "public_tier_sg"
  description = "Public facing services (e.g. ALB)"
  vpc_id      = aws_vpc.insecure_vpc.id

  ingress {
    description = "Allow HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    description = "Allow outbound to internet securely"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "app_sg" {
  name        = "app_tier_sg"
  description = "App tier (e.g. EKS Nodes)"
  vpc_id      = aws_vpc.insecure_vpc.id

  ingress {
    description     = "Allow traffic from Public SG"
    from_port       = 443
    to_port         = 443
    protocol        = "tcp"
    security_groups = [aws_security_group.public_sg.id]
  }
  egress {
    description = "Allow internal outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["10.0.0.0/16"]
  }
}

resource "aws_security_group" "data_sg" {
  name        = "data_tier_sg"
  description = "Data tier (e.g. Databases)"
  vpc_id      = aws_vpc.insecure_vpc.id

  ingress {
    description     = "Allow DB traffic from App SG"
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [aws_security_group.app_sg.id]
  }
  # No egress allowed from data tier unless absolutely necessary
}

# -------------------------------------------------------------
# Network ACLs (Defense in Depth)
# -------------------------------------------------------------
resource "aws_network_acl" "data_nacl" {
  vpc_id     = aws_vpc.insecure_vpc.id
  subnet_ids = [aws_subnet.data_subnet_1.id, aws_subnet.data_subnet_2.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.3.0/24" # App Subnet 1
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "10.0.4.0/24" # App Subnet 2
    from_port  = 3306
    to_port    = 3306
  }

  # Deny all other inbound

  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/16"
    from_port  = 1024
    to_port    = 65535
  }
}

# -------------------------------------------------------------
# EKS Cluster (Moved to App Tier)
# -------------------------------------------------------------
# tfsec:ignore:aws-eks-encrypt-secrets
resource "aws_eks_cluster" "insecure_eks" {
  name     = "insecure-cluster"
  role_arn = "arn:aws:iam::123456789012:role/FakeAdminRole"

  vpc_config {
    # Secure: Moved to App Tier subnets instead of Public
    subnet_ids              = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]
    security_group_ids      = [aws_security_group.app_sg.id]
    endpoint_public_access  = false
    public_access_cidrs     = ["192.168.1.0/24"]
    endpoint_private_access = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
