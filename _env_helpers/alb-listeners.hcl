# -----------------------------------------------------------------------------
# ALB LISTENERS ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates ALB listeners that attach to an existing ALB and route
# traffic to target groups. Configuration defined in root.hcl or environment.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/alb-listeners"
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

dependency "alb" {
  config_path  = "../alb"
  skip_outputs = true

  mock_outputs = {
    alb_arn      = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/mock-alb/1234567890abcdef"
    alb_dns_name = "mock-alb-123456789.us-east-1.elb.amazonaws.com"
  }
}

dependency "alb_target_groups" {
  config_path  = "../alb-target-groups"
  skip_outputs = true

  mock_outputs = {
    target_group_arns = {
      app = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/mock-app-tg/1234567890abcdef"
    }
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  alb_arn = dependency.alb.outputs.alb_arn

  # Listeners and listener_rules from root.hcl
  listeners      = local.root.inputs.listeners
  listener_rules = lookup(local.root.inputs, "listener_rules", {})

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
