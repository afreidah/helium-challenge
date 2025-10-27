# -----------------------------------------------------------------------------
# SECRETS MANAGER MODULE TEST SUITE
# -----------------------------------------------------------------------------
#
# Tests the Secrets Manager module for secret creation, versioning, rotation
# configuration, and IAM policy generation. Does NOT test simple variable
# passthrough - focuses on module logic and conditional resource creation.
# -----------------------------------------------------------------------------

# Test variables
variables {
  test_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  test_lambda_arn = "arn:aws:lambda:us-east-1:123456789012:function:SecretsManagerRotation"
  test_secret_json = jsonencode({
    username = "dbadmin"
    password = "TestPassword123!"
    host     = "db.example.com"
    port     = 5432
  })
}

# ----------------------------------------------------------------
# Basic secret creation
# Expected: Secret and version created with default settings
# ----------------------------------------------------------------
run "basic_secret" {
  command = plan

  variables {
    secrets = {
      "/production/database/credentials" = {
        description   = "Database credentials"
        secret_string = var.test_secret_json
      }
    }
  }

  # Assert secret created
  assert {
    condition     = length(aws_secretsmanager_secret.this) == 1
    error_message = "Should create exactly 1 secret"
  }

  # Assert secret version created
  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 1
    error_message = "Should create exactly 1 secret version"
  }

  # Assert default recovery window
  assert {
    condition     = aws_secretsmanager_secret.this["/production/database/credentials"].recovery_window_in_days == 30
    error_message = "Default recovery window should be 30 days"
  }
}

# ----------------------------------------------------------------
# Multiple secrets
# Expected: Multiple secrets created independently
# ----------------------------------------------------------------
run "multiple_secrets" {
  command = plan

  variables {
    secrets = {
      "/production/database/master" = {
        description   = "Database master password"
        secret_string = "MasterPassword123!"
        kms_key_id    = var.test_kms_key_id
      }
      "/production/api/key" = {
        description   = "API key for external service"
        secret_string = "api-key-12345"
      }
      "/production/app/config" = {
        description   = "Application configuration"
        secret_string = var.test_secret_json
      }
    }
  }

  # Assert correct number of secrets
  assert {
    condition     = length(aws_secretsmanager_secret.this) == 3
    error_message = "Should create 3 secrets"
  }

  # Assert correct number of versions
  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 3
    error_message = "Should create 3 secret versions"
  }
}

# ----------------------------------------------------------------
# Custom recovery window
# Expected: Secret created with custom recovery window
# ----------------------------------------------------------------
run "custom_recovery_window" {
  command = plan

  variables {
    secrets = {
      "/production/temporary/secret" = {
        description             = "Temporary secret"
        secret_string           = "temp123"
        recovery_window_in_days = 7
      }
    }
  }

  # Assert custom recovery window
  assert {
    condition     = aws_secretsmanager_secret.this["/production/temporary/secret"].recovery_window_in_days == 7
    error_message = "Recovery window should be 7 days when specified"
  }
}

# ----------------------------------------------------------------
# KMS encryption
# Expected: Secret uses specified KMS key
# ----------------------------------------------------------------
run "kms_encryption" {
  command = plan

  variables {
    secrets = {
      "/production/sensitive/data" = {
        description   = "Sensitive data"
        secret_string = "secret123"
        kms_key_id    = var.test_kms_key_id
      }
    }
  }

  # Assert KMS key specified
  assert {
    condition     = aws_secretsmanager_secret.this["/production/sensitive/data"].kms_key_id == var.test_kms_key_id
    error_message = "Secret should use specified KMS key"
  }
}

# ----------------------------------------------------------------
# Rotation configuration enabled
# Expected: Rotation resource created when Lambda ARN provided
# ----------------------------------------------------------------
run "rotation_enabled" {
  command = plan

  variables {
    secrets = {
      "/production/database/rotated" = {
        description         = "Auto-rotated database credentials"
        secret_string       = var.test_secret_json
        rotation_lambda_arn = var.test_lambda_arn
        rotation_days       = 30
      }
    }
  }

  # Assert rotation resource created
  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 1
    error_message = "Rotation should be configured when Lambda ARN provided"
  }

  # Assert rotation schedule
  assert {
    condition     = aws_secretsmanager_secret_rotation.this["/production/database/rotated"].rotation_rules[0].automatically_after_days == 30
    error_message = "Rotation should occur every 30 days"
  }
}

# ----------------------------------------------------------------
# Rotation configuration disabled
# Expected: No rotation resource when Lambda ARN not provided
# ----------------------------------------------------------------
run "rotation_disabled" {
  command = plan

  variables {
    secrets = {
      "/production/static/secret" = {
        description         = "Static secret without rotation"
        secret_string       = "static123"
        rotation_lambda_arn = null
      }
    }
  }

  # Assert no rotation resource created
  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 0
    error_message = "Rotation should not be configured when Lambda ARN is null"
  }
}

# ----------------------------------------------------------------
# Mixed rotation configuration
# Expected: Rotation only on secrets with Lambda ARN
# ----------------------------------------------------------------
run "mixed_rotation" {
  command = plan

  variables {
    secrets = {
      "/production/rotated/secret" = {
        description         = "Rotated secret"
        secret_string       = "rotated123"
        rotation_lambda_arn = var.test_lambda_arn
        rotation_days       = 60
      }
      "/production/static/secret" = {
        description   = "Static secret"
        secret_string = "static123"
      }
    }
  }

  # Assert only one rotation resource
  assert {
    condition     = length(aws_secretsmanager_secret_rotation.this) == 1
    error_message = "Only secrets with Lambda ARN should have rotation configured"
  }

  # Assert correct secret has rotation
  assert {
    condition     = aws_secretsmanager_secret_rotation.this["/production/rotated/secret"].rotation_rules[0].automatically_after_days == 60
    error_message = "Rotation should be configured for rotated secret with 60 day interval"
  }
}

# ----------------------------------------------------------------
# IAM read policy not created by default
# Expected: No IAM policy when create_read_policy is false
# ----------------------------------------------------------------
run "no_iam_policy_by_default" {
  command = plan

  variables {
    secrets = {
      "/production/test/secret" = {
        description   = "Test secret"
        secret_string = "test123"
      }
    }
    create_read_policy = false
  }

  # Assert no IAM policy created
  assert {
    condition     = length(aws_iam_policy.read_secrets) == 0
    error_message = "IAM policy should not be created when create_read_policy is false"
  }
}

# ----------------------------------------------------------------
# IAM read policy creation
# Expected: IAM policy created when enabled
# ----------------------------------------------------------------
run "iam_policy_created" {
  command = plan

  variables {
    secrets = {
      "/production/app/secret" = {
        description   = "App secret"
        secret_string = "app123"
      }
    }
    create_read_policy = true
    policy_name_prefix = "production"
    kms_key_arn        = var.test_kms_key_id
  }

  # Assert IAM policy created
  assert {
    condition     = length(aws_iam_policy.read_secrets) == 1
    error_message = "IAM policy should be created when create_read_policy is true"
  }

  # Assert policy name follows pattern
  assert {
    condition     = aws_iam_policy.read_secrets[0].name == "production-read-secrets"
    error_message = "IAM policy name should follow {prefix}-read-secrets pattern"
  }
}

# ----------------------------------------------------------------
# Tags applied to secrets
# Expected: Tags merged with Name tag
# ----------------------------------------------------------------
run "tags_applied" {
  command = plan

  variables {
    secrets = {
      "/production/tagged/secret" = {
        description   = "Tagged secret"
        secret_string = "tagged123"
      }
    }
    tags = {
      Environment = "production"
      Team        = "platform"
    }
  }

  # Assert Environment tag present
  assert {
    condition     = aws_secretsmanager_secret.this["/production/tagged/secret"].tags["Environment"] == "production"
    error_message = "Environment tag should be applied"
  }

  # Assert Team tag present
  assert {
    condition     = aws_secretsmanager_secret.this["/production/tagged/secret"].tags["Team"] == "platform"
    error_message = "Team tag should be applied"
  }

  # Assert Name tag follows secret name
  assert {
    condition     = aws_secretsmanager_secret.this["/production/tagged/secret"].tags["Name"] == "/production/tagged/secret"
    error_message = "Name tag should match secret name"
  }
}

# ----------------------------------------------------------------
# Empty secrets map
# Expected: No resources created
# ----------------------------------------------------------------
run "no_secrets" {
  command = plan

  variables {
    secrets = {}
  }

  # Assert no secrets created
  assert {
    condition     = length(aws_secretsmanager_secret.this) == 0
    error_message = "Should create 0 secrets when secrets map is empty"
  }

  # Assert no versions created
  assert {
    condition     = length(aws_secretsmanager_secret_version.this) == 0
    error_message = "Should create 0 versions when secrets map is empty"
  }
}
