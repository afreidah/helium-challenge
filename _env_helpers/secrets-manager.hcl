# -----------------------------------------------------------------------------
# SECRETS MANAGER ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
#
# This helper provides the Terraform source and default configuration for the
# Secrets Manager module across all environments. It creates secrets for Aurora
# database credentials and other sensitive application configuration.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/secrets-manager"
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

dependency "kms" {
  config_path  = "../kms"
  skip_outputs = true

  mock_outputs = {
    key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

dependency "aurora" {
  config_path  = "../aurora-postgresql"
  skip_outputs = true

  mock_outputs = {
    cluster_endpoint        = "placeholder.cluster-xxx.us-east-1.rds.amazonaws.com"
    cluster_reader_endpoint = "placeholder.cluster-ro-xxx.us-east-1.rds.amazonaws.com"
    cluster_port            = 5432
    cluster_database_name   = "postgres"
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # Build secrets map with real Aurora values injected via Terragrunt
  # All secrets configuration comes from root.hcl secrets_config
  secrets = {
    for key, config in local.root.inputs.secrets_config :
    key => merge(
      config,
      # Inject KMS key into all secrets
      {
        kms_key_id = dependency.kms.outputs.key_id
      },
      # For Aurora secrets, inject real connection details
      can(regex("/aurora/", key)) ? {
        secret_string = jsonencode(
          merge(
            jsondecode(config.secret_string),
            {
              host        = dependency.aurora.outputs.cluster_endpoint
              reader_host = dependency.aurora.outputs.cluster_reader_endpoint
              port        = dependency.aurora.outputs.cluster_port
              dbname      = dependency.aurora.outputs.cluster_database_name
            }
          )
        )
      } : {}
    )
  }

  # Create IAM read policy for EKS pods
  create_read_policy = true
  policy_name_prefix = "${local.root.inputs.environment}-app"
  kms_key_arn        = dependency.kms.outputs.key_arn

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
