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
  # Role configuration from root.hcl iam_role_configs
  # This will be overridden by the environment-level terragrunt.hcl
  # Example: role_config = local.root.inputs.iam_role_configs.eks_cluster

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
