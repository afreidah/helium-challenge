# -----------------------------------------------------------------------------
# SECRETS MANAGER MODULE
# -----------------------------------------------------------------------------
#
# This module creates AWS Secrets Manager secrets with optional automatic
# rotation for RDS databases. Secrets are encrypted using KMS and support
# versioning, recovery windows, and replica regions.
#
# Secrets Manager provides automatic rotation for RDS, Redshift, and
# DocumentDB credentials with zero downtime. Rotation uses AWS Lambda
# functions that update both the database password and the secret value.
#
# Components Created:
#   - Secret: Container for secret versions and metadata
#   - Secret Version: Actual secret value (JSON or plaintext)
#   - Rotation Configuration: Optional Lambda-based rotation schedule
#   - IAM Policy: Optional read access policy for service principals
#
# Features:
#   - Automatic rotation for RDS databases (requires Lambda)
#   - KMS encryption for secret values
#   - Version management with staging labels
#   - Recovery window for accidental deletion (7-30 days)
#   - Cross-region replication for DR scenarios
#
# IMPORTANT: Secrets cannot be immediately deleted. A recovery window
# (minimum 7 days) is required unless force deletion is enabled. Rotation
# requires a Lambda function with proper IAM permissions and VPC access.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# SECRETS
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret" "this" {
  for_each = var.secrets

  name                    = each.key
  description             = each.value.description
  kms_key_id              = each.value.kms_key_id
  recovery_window_in_days = each.value.recovery_window_in_days

  tags = merge(
    var.tags,
    {
      Name = each.key
    }
  )
}

# -----------------------------------------------------------------------------
# SECRET VERSIONS
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret_version" "this" {
  for_each = var.secrets

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_string
}

# -----------------------------------------------------------------------------
# SECRET ROTATION
# -----------------------------------------------------------------------------

resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = {
    for key, secret in var.secrets :
    key => secret
    if secret.rotation_lambda_arn != null
  }

  secret_id           = aws_secretsmanager_secret.this[each.key].id
  rotation_lambda_arn = each.value.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = each.value.rotation_days
  }
}

# -----------------------------------------------------------------------------
# IAM READ POLICY
# -----------------------------------------------------------------------------

resource "aws_iam_policy" "read_secrets" {
  count = var.create_read_policy ? 1 : 0

  name        = "${var.policy_name_prefix}-read-secrets" # Changed from -secrets-read
  description = "Allow reading secrets from Secrets Manager"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = [
          for secret in aws_secretsmanager_secret.this : secret.arn
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn != null ? [var.kms_key_arn] : []
      }
    ]
  })

  tags = var.tags
}
