# -----------------------------------------------------------------------------
# IAM ROLE - EKS CLUSTER
# -----------------------------------------------------------------------------
# Creates IAM role for the EKS cluster control plane with permissions to
# manage cluster resources and integrate with AWS services.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "iam_role" {
  path = "${get_repo_root()}/_env_helpers/iam-role.hcl"
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
  role_config = local.root.inputs.iam_role_configs.eks_cluster
}
