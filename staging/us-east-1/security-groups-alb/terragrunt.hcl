# -----------------------------------------------------------------------------
# SECURITY GROUP - APPLICATION LOAD BALANCER
# -----------------------------------------------------------------------------
# Creates security group for the Application Load Balancer with rules allowing
# HTTP/HTTPS traffic from the internet and outbound to EKS nodes.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security_groups" {
  path = "${get_repo_root()}/_env_helpers/security-groups.hcl"
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
  security_group_rules = local.root.locals.security_group_rules.alb
}
