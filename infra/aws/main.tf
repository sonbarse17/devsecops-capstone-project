terraform {
  backend "s3" {}
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_kms_key" "eks_secrets_kms_key" {
  description             = "CMK for EKS secrets encryption"
  deletion_window_in_days = 10
  enable_key_rotation     = true
}

resource "aws_kms_alias" "eks_secrets_kms_alias" {
  name          = "alias/devsecops-eks-secrets"
  target_key_id = aws_kms_key.eks_secrets_kms_key.key_id
}

resource "aws_vpc" "insecure_vpc" {
  cidr_block           = "172.16.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = { Name = "devsecops-vpc" }
}

resource "aws_subnet" "public_subnet_1" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "172.16.1.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags                    = { Name = "public-subnet-1" }
}

resource "aws_subnet" "public_subnet_2" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "172.16.2.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags                    = { Name = "public-subnet-2" }
}

resource "aws_subnet" "app_subnet_1" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "172.16.3.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags                    = { Name = "app-subnet-1" }
}

resource "aws_subnet" "app_subnet_2" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "172.16.4.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags                    = { Name = "app-subnet-2" }
}

resource "aws_subnet" "data_subnet_1" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "172.16.5.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1a"
  tags                    = { Name = "data-subnet-1" }
}

resource "aws_subnet" "data_subnet_2" {
  vpc_id                  = aws_vpc.insecure_vpc.id
  cidr_block              = "172.16.6.0/24"
  map_public_ip_on_launch = false
  availability_zone       = "us-east-1b"
  tags                    = { Name = "data-subnet-2" }
}


resource "aws_security_group" "public_sg" {
  name        = "public_tier_sg"
  description = "Public facing services (e.g. ALB)"
  vpc_id      = aws_vpc.insecure_vpc.id

  ingress {
    description = "Allow HTTPS from Internet"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
  }
  egress {
    description = "Allow outbound to internet securely"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["172.16.0.0/16"]
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
    cidr_blocks = ["172.16.0.0/16"]
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
}

resource "aws_network_acl" "data_nacl" {
  vpc_id     = aws_vpc.insecure_vpc.id
  subnet_ids = [aws_subnet.data_subnet_1.id, aws_subnet.data_subnet_2.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "172.16.3.0/24"
    from_port  = 3306
    to_port    = 3306
  }

  ingress {
    protocol   = "tcp"
    rule_no    = 110
    action     = "allow"
    cidr_block = "172.16.4.0/24"
    from_port  = 3306
    to_port    = 3306
  }


  egress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "172.16.0.0/16"
    from_port  = 1024
    to_port    = 65535
  }
}

resource "aws_eks_cluster" "insecure_eks" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn

  encryption_config {
    provider {
      key_arn = aws_kms_key.eks_secrets_kms_key.arn
    }
    resources = ["secrets"]
  }

  vpc_config {
    subnet_ids              = [aws_subnet.app_subnet_1.id, aws_subnet.app_subnet_2.id]
    security_group_ids      = [aws_security_group.app_sg.id]
    endpoint_public_access  = false
    public_access_cidrs     = ["192.168.1.0/24"]
    endpoint_private_access = true
  }

  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}
