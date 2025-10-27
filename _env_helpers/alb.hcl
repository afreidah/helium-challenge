# -----------------------------------------------------------------------------
# ALB ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates an Application Load Balancer with configuration defined
# in root.hcl and dependencies on general-networking and security-groups-alb.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/alb"
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

dependency "security_groups_alb" {
  config_path  = "../security-groups-alb"
  skip_outputs = true

  mock_outputs = {
    security_group_id = "sg-mock1234567890abc"
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # Pass the entire alb_config as a nested object with required fields added
  alb_config = merge(
    local.root.inputs.alb_config,
    {
      name_suffix        = "alb"
      subnet_ids         = dependency.general_networking.outputs.public_subnet_ids
      security_group_ids = [dependency.security_groups_alb.outputs.security_group_id]
    }
  )

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
