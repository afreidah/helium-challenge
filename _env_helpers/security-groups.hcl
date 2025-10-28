# -----------------------------------------------------------------------------
# SECURITY GROUPS ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates a security group with rules defined in root.hcl.
# Each environment component specifies which rule set to use via inputs merge.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/security-group"
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

dependency "general_networking" {
  config_path = "../general-networking"

  mock_outputs = {
    vpc_id = "vpc-mock1234567890abc"
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  vpc_id = dependency.general_networking.outputs.vpc_id

  # Security group rules configuration from root.hcl security_group_rules
  # This will be overridden by the environment-level terragrunt.hcl
  # Example: security_group_rules = local.root.inputs.security_group_rules.alb

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
