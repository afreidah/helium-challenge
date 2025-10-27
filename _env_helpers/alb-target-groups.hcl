# -----------------------------------------------------------------------------
# ALB TARGET GROUPS ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates ALB target groups with configuration defined in root.hcl
# and dependency on general-networking for VPC ID.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/alb-target-groups"
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
  config_path  = "../general-networking"
  skip_outputs = true

  mock_outputs = {
    vpc_id             = "vpc-mock1234567890abc"
    public_subnet_ids  = ["subnet-mock1", "subnet-mock2"]
    private_subnet_ids = ["subnet-mock3", "subnet-mock4"]
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  vpc_id = dependency.general_networking.outputs.vpc_id

  # Target groups configuration from root.hcl or environment override
  # target_groups will be provided by environment-specific inputs merge

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
