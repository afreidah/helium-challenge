# Secrets Manager Module

Bare-bones AWS Secrets Manager module for storing and managing sensitive credentials.

## Features

- ✅ KMS encryption for secret values
- ✅ Automatic rotation support (requires Lambda)
- ✅ Version management with staging labels
- ✅ Recovery window for accidental deletion
- ✅ Optional IAM read policy generation

## Usage

### Basic Secret

```hcl
module "secrets" {
  source = "./modules/secrets-manager"

  secrets = {
    "/production/database/credentials" = {
      description   = "Aurora PostgreSQL credentials"
      secret_string = jsonencode({
        username = "dbadmin"
        password = "SecurePassword123!"
        host     = "aurora.cluster-xyz.us-east-1.rds.amazonaws.com"
        port     = 5432
      })
      kms_key_id = aws_kms_key.main.id
    }
  }

  tags = {
    Environment = "production"
    ManagedBy   = "Terraform"
  }
}
```

### With Automatic Rotation

```hcl
module "secrets" {
  source = "./modules/secrets-manager"

  secrets = {
    "/production/rds/master" = {
      description         = "RDS master password with rotation"
      secret_string       = jsonencode({ username = "admin", password = "initial" })
      kms_key_id          = aws_kms_key.main.id
      rotation_lambda_arn = aws_lambda_function.rotate_secret.arn
      rotation_days       = 30
    }
  }
}
```

### With IAM Read Policy

```hcl
module "secrets" {
  source = "./modules/secrets-manager"

  secrets = {
    "/production/app/config" = {
      description   = "Application secrets"
      secret_string = jsonencode({ api_key = "abc123" })
    }
  }

  create_read_policy = true
  policy_name_prefix = "production-app"
  kms_key_arn        = aws_kms_key.main.arn
}

# Attach policy to EKS pod role
resource "aws_iam_role_policy_attachment" "app_secrets" {
  role       = aws_iam_role.app_pod.name
  policy_arn = module.secrets.read_policy_arn
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| secrets | Map of secrets to create | `map(object)` | `{}` | no |
| create_read_policy | Create IAM policy for reading secrets | `bool` | `false` | no |
| policy_name_prefix | Prefix for IAM policy name | `string` | `"secretsmanager"` | no |
| kms_key_arn | KMS key ARN for IAM policy | `string` | `"*"` | no |
| tags | Tags to apply to all secrets | `map(string)` | `{}` | no |

### Secret Object

```hcl
{
  description             = optional(string)
  secret_string           = string
  kms_key_id              = optional(string)
  recovery_window_in_days = optional(number, 30)
  rotation_lambda_arn     = optional(string)
  rotation_days           = optional(number, 30)
}
```

## Outputs

| Name | Description |
|------|-------------|
| secret_arns | Map of secret ARNs |
| secret_ids | Map of secret IDs |
| secret_versions | Map of secret version IDs |
| read_policy_arn | ARN of IAM read policy (if created) |
| read_policy_name | Name of IAM read policy (if created) |

## Notes

- Secrets have a minimum 7-day recovery window before permanent deletion
- Secret values are ignored after initial creation (use AWS Console or CLI to update)
- Rotation requires a Lambda function with VPC access to the database
- KMS key must allow `kms:Decrypt` for principals reading the secret
