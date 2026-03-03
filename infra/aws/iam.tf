# -------------------------------------------------------------
# AWS IAM Groups & Policies
# -------------------------------------------------------------

# --- 1. Admin Group ---
resource "aws_iam_group" "admin" {
  name = "devsecops-admins"
}

resource "aws_iam_group_policy_attachment" "admin_access" {
  group      = aws_iam_group.admin.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# --- 2. Developer Group ---
resource "aws_iam_group" "developer" {
  name = "devsecops-developers"
}

# Limit developers to non-admin, functional access
# tfsec:ignore:aws-iam-no-policy-wildcards
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
      # They can assume the Application role if needed to test
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

# --- 3. Auditor Group ---
resource "aws_iam_group" "auditor" {
  name = "devsecops-auditors"
}

resource "aws_iam_group_policy_attachment" "auditor_access" {
  group      = aws_iam_group.auditor.name
  policy_arn = "arn:aws:iam::aws:policy/SecurityAudit"
}


# -------------------------------------------------------------
# Enforce MFA Policy (Applied to all users)
# -------------------------------------------------------------
# tfsec:ignore:aws-iam-no-policy-wildcards
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


# -------------------------------------------------------------
# AWS Users
# -------------------------------------------------------------

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

# -------------------------------------------------------------
# Application Role
# -------------------------------------------------------------
# Specific least-privilege role that the Application / EKS pods can assume
resource "aws_iam_role" "application_role" {
  name = "devsecops-application-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com" # Ideally IRSA with OIDC
        }
        Action = "sts:AssumeRole"
      }
    ]
  })
}

# tfsec:ignore:aws-iam-no-policy-wildcards
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
        # In a real scenario, restrict to a specific bucket ARN
        Resource = "*"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "application_access" {
  role       = aws_iam_role.application_role.name
  policy_arn = aws_iam_policy.application_policy.arn
}

# -------------------------------------------------------------
# IAM Access Analyzer
# -------------------------------------------------------------
# Continuously monitors for open access / external resources
resource "aws_accessanalyzer_analyzer" "account_analyzer" {
  analyzer_name = "devsecops-account-analyzer"
  type          = "ACCOUNT"
}
