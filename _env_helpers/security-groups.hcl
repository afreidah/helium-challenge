# -----------------------------------------------------------------------------
# SECURITY GROUPS ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates a security group with rules defined in root.hcl.
# The appropriate rule set is automatically selected based on component name.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/security-group"
}

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  
  # Parse component from the calling directory (not the helper directory)
  repo_root     = get_repo_root()
  calling_dir   = get_terragrunt_dir()  # This is the environment dir, not the helper dir
  relative_path = replace(local.calling_dir, "${local.repo_root}/", "")
  path_parts    = split("/", local.relative_path)
  component     = length(local.path_parts) > 2 ? local.path_parts[4] : ""
  
  # Map component to rule set key
  component_to_rules = {
    "security-groups-alb"         = "alb"
    "security-groups-aurora"      = "aurora"
    "security-groups-eks-cluster" = "eks_cluster"
    "security-groups-eks-nodes"   = "eks_nodes"
  }
  
  rule_key = local.component_to_rules[local.component]
}

dependency "general_networking" {
  config_path = "../general-networking"
  mock_outputs = {
    vpc_id = "vpc-mock1234567890abc"
  }
}

inputs = {
  vpc_id = dependency.general_networking.outputs.vpc_id
  
  # Select rule set based on component name
  security_group_rules = local.root.inputs.security_group_rules[local.rule_key]
}
