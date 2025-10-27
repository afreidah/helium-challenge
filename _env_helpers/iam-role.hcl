# -----------------------------------------------------------------------------
# IAM ROLE ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates an IAM role with configuration defined in root.hcl.
# Each environment component specifies which role config to use via inputs merge.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/iam-role"
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  environment = local.root.inputs.environment
  region      = local.root.inputs.region

  # This will be overridden by the environment-level inputs merge
  role_config = {}

  tags = local.root.inputs.common_tags
}
