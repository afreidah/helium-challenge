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

  # These will all be provided by root.hcl through the include
  # environment, region, tags, etc. are inherited

  # This will be overridden by the environment-level inputs merge
  security_group_rules = {}
}
