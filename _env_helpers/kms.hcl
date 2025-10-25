# -----------------------------------------------------------------------------
# KMS ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
#
# This file provides the terraform source and default configuration for the
# KMS key module across all environments. It creates a single infrastructure
# encryption key used for EKS cluster secrets, Aurora PostgreSQL, EBS volumes,
# and CloudWatch logs encryption.
#
# Directory Structure Expected:
#   <environment>/<region>/kms/terragrunt.hcl
#
# The child terragrunt.hcl only needs:
#   include "root" { path = find_in_parent_folders("root.hcl") }
#   include "kms" { path = "${get_repo_root()}/_env_helpers/kms.hcl" }
#
# Optional overrides can be added in the child file for specific environments.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/kms"
}

# -----------------------------------------------------------------------------
# Local Environment
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# MODULE INPUTS
# -----------------------------------------------------------------------------

inputs = {
  # Key description includes environment for clarity
  description = "${local.root.inputs.environment} infrastructure encryption key for EKS, Aurora, and EBS"

  # Human-readable alias for easy reference in other modules
  # Format: <environment>-<region>-infra
  alias_name = "${local.root.inputs.environment}-${local.root.inputs.region}-infra"

  # Security best practices
  enable_key_rotation     = true
  deletion_window_in_days = 30

  # Key policy (null = use AWS default policy which grants account root full access)
  # Can be overridden in child terragrunt.hcl if custom IAM permissions needed
  policy = null

  # Tags from root configuration
  tags = local.root.inputs.common_tags
}
