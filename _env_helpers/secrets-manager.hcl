# -----------------------------------------------------------------------------
# SECRETS MANAGER ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
#
# This file provides the terraform source and default configuration for the
# Secrets Manager module across all environments. It creates secrets for
# Aurora database credentials and other sensitive application configuration.
#
# The module accepts dependency outputs at the top level, avoiding Terragrunt
# expression evaluation limitations with nested dependency references.
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
# DEPENDENCIES
# -----------------------------------------------------------------------------

# KMS key for encrypting secrets
dependency "kms" {
  config_path  = "../kms"

  mock_outputs = {
    key_id  = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

# Aurora cluster for connection details
dependency "aurora" {
  config_path  = "../aurora-postgresql"

  mock_outputs = {
    cluster_endpoint        = "mock-aurora.cluster-xyz.us-east-1.rds.amazonaws.com"
    cluster_reader_endpoint = "mock-aurora.cluster-ro-xyz.us-east-1.rds.amazonaws.com"
    cluster_port            = 5432
    cluster_database_name   = "appdb"
    cluster_master_username = "postgres"
  }
}

# -----------------------------------------------------------------------------
# INPUTS
# -----------------------------------------------------------------------------

inputs = {
  # Secrets configuration from root.hcl
  secrets = local.root.inputs.secrets_config
  
  # Inject KMS key ID into all secrets (module handles this)
  kms_key_id = dependency.kms.outputs.key_id
  
  # Inject Aurora endpoints into master credentials secret (module handles this)
  aurora_endpoint        = dependency.aurora.outputs.cluster_endpoint
  aurora_reader_endpoint = dependency.aurora.outputs.cluster_reader_endpoint
  aurora_port            = dependency.aurora.outputs.cluster_port
  aurora_database_name   = dependency.aurora.outputs.cluster_database_name
  
  # Create IAM read policy for EKS pods
  create_read_policy = true
  policy_name_prefix = "${local.root.locals.environment}-app"
  kms_key_arn        = dependency.kms.outputs.key_arn

  # Tags from root (inherited automatically via root.hcl inputs)
}
