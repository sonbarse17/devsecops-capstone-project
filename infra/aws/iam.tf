
data "aws_caller_identity" "current" {}

resource "aws_iam_role" "eks_cluster_role" {
  name = "devsecops-eks-cluster-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}

resource "aws_iam_role_policy_attachment" "eks_vpc_resource_controller_policy" {
  role       = aws_iam_role.eks_cluster_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
}


resource "aws_iam_group" "admin" {
  name = "devsecops-admins"
}

resource "aws_iam_group_policy_attachment" "admin_access" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

resource "aws_iam_group" "developer" {
  name = "devsecops-developers"
}

resource "aws_iam_policy" "developer_policy" {
  name        = "DeveloperPolicy"
  description = "Allows developers to manage application resources but not IAM/Security roles"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ec2:Describe*",
          "eks:DescribeCluster",
          "eks:ListClusters",
          "s3:List*",
          "logs:Get*",
          "logs:Describe*"
        ]
        Resource = "*"
      },
      {
        Effect   = "Allow"
        Action   = "sts:AssumeRole"
        Resource = aws_iam_role.application_role.arn
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "developer_access" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.developer_policy.arn
}

resource "aws_iam_group" "auditor" {
  name = "devsecops-auditors"
}

resource "aws_iam_group_policy_attachment" "auditor_access" {
  group      = aws_iam_group.auditor.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}


resource "aws_iam_policy" "force_mfa" {
  name        = "ForceMFA"
  description = "Requires MFA to perform any API actions"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "DenyAllExceptListedIfNoMFA"
        Effect   = "Deny"
        Action   = "*"
        Resource = "*"
        Condition = {
          BoolIfExists = {
            "aws:MultiFactorAuthPresent" = "false"
          }
        }
      }
    ]
  })
}

resource "aws_iam_group_policy_attachment" "admin_mfa" {
  group      = aws_iam_group.admin.name
  policy_arn = aws_iam_policy.force_mfa.arn
}
resource "aws_iam_group_policy_attachment" "developer_mfa" {
  group      = aws_iam_group.developer.name
  policy_arn = aws_iam_policy.force_mfa.arn
}
resource "aws_iam_group_policy_attachment" "auditor_mfa" {
  group      = aws_iam_group.auditor.name
  policy_arn = aws_iam_policy.force_mfa.arn
}



resource "aws_iam_user" "admin_user" {
  name = "alice-admin"
}

resource "aws_iam_user_group_membership" "admin_membership" {
  user   = aws_iam_user.admin_user.name
  groups = [aws_iam_group.admin.name]
}

resource "aws_iam_user" "developer_user" {
  name = "bob-developer"
}

resource "aws_iam_user_group_membership" "developer_membership" {
  user   = aws_iam_user.developer_user.name
  groups = [aws_iam_group.developer.name]
}

resource "aws_iam_user" "auditor_user" {
  name = "charlie-auditor"
}

resource "aws_iam_user_group_membership" "auditor_membership" {
  user   = aws_iam_user.auditor_user.name
  groups = [aws_iam_group.auditor.name]
}

resource "aws_iam_role" "application_role" {
  name = "devsecops-application-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          AWS = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:root"
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_policy" "application_policy" {
  name        = "ApplicationPolicy"
  description = "Least privilege access for the application"
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:PutObject"
        ]
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "application_access" {
  role       = aws_iam_role.application_role.name
  policy_arn = aws_iam_policy.application_policy.arn
}

resource "aws_accessanalyzer_analyzer" "account_analyzer" {
  count         = var.enable_account_access_analyzer ? 1 : 0
  analyzer_name = "devsecops-account-analyzer"
  type          = "ACCOUNT"
}
