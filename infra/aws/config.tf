# -------------------------------------------------------------
# AWS Config & Continuous Compliance
# -------------------------------------------------------------

# IAM Role for AWS Config to read resource configurations
resource "aws_iam_role" "aws_config_role" {
  name = "devsecops-aws-config-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "config.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "aws_config_policy_attachment" {
  role       = aws_iam_role.aws_config_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWS_ConfigRole"
}

# The AWS Config Recorder (monitors all resources in region)
resource "aws_config_configuration_recorder" "main" {
  name     = "devsecops-config-recorder"
  role_arn = aws_iam_role.aws_config_role.arn

  recording_group {
    all_supported                 = true
    include_global_resource_types = true
  }
}

# -------------------------------------------------------------
# Delivery Channel: S3 Bucket for AWS Config
# -------------------------------------------------------------
# tfsec:ignore:aws-s3-enable-bucket-logging
# tfsec:ignore:aws-s3-enable-versioning
# tfsec:ignore:aws-s3-encryption-customer-key
resource "aws_s3_bucket" "config_bucket" {
  bucket_prefix = "devsecops-awsconfig-"
  force_destroy = true
}

resource "aws_s3_bucket_server_side_encryption_configuration" "config_bucket_encryption" {
  bucket = aws_s3_bucket.config_bucket.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "block_public" {
  bucket                  = aws_s3_bucket.config_bucket.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# tfsec:ignore:aws-iam-no-policy-wildcards
resource "aws_iam_role_policy" "aws_config_s3_policy" {
  name = "aws-config-s3-policy"
  role = aws_iam_role.aws_config_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "s3:PutObject",
          "s3:GetBucketAcl"
        ]
        Effect = "Allow"
        Resource = [
          aws_s3_bucket.config_bucket.arn,
          "${aws_s3_bucket.config_bucket.arn}/*"
        ]
        Condition = {
          StringLike = {
            "s3:x-amz-acl" = "bucket-owner-full-control"
          }
        }
      }
    ]
  })
}

resource "aws_config_delivery_channel" "main" {
  name           = "devsecops-delivery-channel"
  s3_bucket_name = aws_s3_bucket.config_bucket.bucket
  depends_on     = [aws_config_configuration_recorder.main]
}

resource "aws_config_configuration_recorder_status" "main" {
  name       = aws_config_configuration_recorder.main.name
  is_enabled = true
  depends_on = [aws_config_delivery_channel.main]
}

# -------------------------------------------------------------
# AWS Config Managed Rules (Compliance Checks)
# -------------------------------------------------------------

# Rule 1: Ensure IAM Users have MFA enabled
resource "aws_config_config_rule" "iam_user_mfa_enabled" {
  name = "iam-user-mfa-enabled"

  source {
    owner             = "AWS"
    source_identifier = "IAM_USER_MFA_ENABLED"
  }
  depends_on = [aws_config_configuration_recorder.main]
}

# Rule 2: Ensure S3 buckets prohibit public read access
resource "aws_config_config_rule" "s3_bucket_public_read_prohibited" {
  name = "s3-bucket-public-read-prohibited"

  source {
    owner             = "AWS"
    source_identifier = "S3_BUCKET_PUBLIC_READ_PROHIBITED"
  }
  depends_on = [aws_config_configuration_recorder.main]
}

# Rule 3: Ensure Security Groups do not allow unrestricted SSH
resource "aws_config_config_rule" "restricted_ssh" {
  name = "restricted-ssh"

  source {
    owner             = "AWS"
    source_identifier = "INCOMING_SSH_DISABLED"
  }
  depends_on = [aws_config_configuration_recorder.main]
}
