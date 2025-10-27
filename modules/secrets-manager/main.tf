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
#   - Dependency injection for Aurora endpoints and KMS keys
#
# IMPORTANT: Secrets cannot be immediately deleted. A recovery window
# (minimum 7 days) is required unless force deletion is enabled. Rotation
# requires a Lambda function with proper IAM permissions and VPC access.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# LOCALS - DEPENDENCY INJECTION
# -----------------------------------------------------------------------------
# Process secrets to inject KMS key and Aurora endpoints from variables

locals {
  # Inject KMS key into all secrets if provided
  secrets_with_kms = {
    for key, secret in var.secrets :
    key => merge(secret, {
      kms_key_id = var.kms_key_id != null ? var.kms_key_id : secret.kms_key_id
    })
  }
  
  # Inject Aurora endpoints into Aurora master credentials secret if provided
  secrets_final = {
    for key, secret in local.secrets_with_kms :
    key => merge(secret, {
      secret_string = (
        # Check if this is an Aurora master credentials secret and we have Aurora data
        can(regex("/aurora/master-credentials$", key)) && var.aurora_endpoint != null ?
        # If yes, merge Aurora connection details into the secret JSON
        jsonencode(merge(
          jsondecode(secret.secret_string),
          {
            host        = var.aurora_endpoint
            reader_host = var.aurora_reader_endpoint
            port        = var.aurora_port
            dbname      = var.aurora_database_name
          }
        )) :
        # Otherwise, use the original secret string
        secret.secret_string
      )
    })
  }
}

# -----------------------------------------------------------------------------
# SECRETS
# -----------------------------------------------------------------------------

# AWS Secrets Manager secrets for credentials and configuration
# Creates one secret per map entry with KMS encryption
resource "aws_secretsmanager_secret" "this" {
  for_each = local.secrets_final

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

# Secret values stored as versions
# Supports both string and JSON secret values
resource "aws_secretsmanager_secret_version" "this" {
  for_each = local.secrets_final

  secret_id     = aws_secretsmanager_secret.this[each.key].id
  secret_string = each.value.secret_string

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# -----------------------------------------------------------------------------
# ROTATION CONFIGURATION
# -----------------------------------------------------------------------------

# Optional automatic rotation for RDS secrets
# Requires Lambda function and proper IAM permissions
resource "aws_secretsmanager_secret_rotation" "this" {
  for_each = { for k, v in local.secrets_final : k => v if v.rotation_lambda_arn != null }

  secret_id           = aws_secretsmanager_secret.this[each.key].id
  rotation_lambda_arn = each.value.rotation_lambda_arn

  rotation_rules {
    automatically_after_days = each.value.rotation_days
  }
}

# -----------------------------------------------------------------------------
# IAM READ POLICY
# -----------------------------------------------------------------------------

# Optional IAM policy for reading secrets
# Can be attached to roles or service principals
resource "aws_iam_policy" "read_secrets" {
  count = var.create_read_policy ? 1 : 0

  name        = "${var.policy_name_prefix}-read-secrets"
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
        Resource = [for secret in aws_secretsmanager_secret.this : secret.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "kms:Decrypt"
        ]
        Resource = var.kms_key_arn
        Condition = {
          StringEquals = {
            "kms:ViaService" = "secretsmanager.${data.aws_region.current.name}.amazonaws.com"
          }
        }
      }
    ]
  })

  tags = var.tags
}

# -----------------------------------------------------------------------------
# DATA SOURCES
# -----------------------------------------------------------------------------

data "aws_region" "current" {}
