# -----------------------------------------------------------------------------
# IAM ROLE - EXTERNAL SECRETS OPERATOR
# -----------------------------------------------------------------------------
# Creates IAM role for External Secrets Operator using IRSA to access
# AWS Secrets Manager. Trust policy dynamically constructed from EKS OIDC.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "iam_role" {
  path = "${get_repo_root()}/_env_helpers/iam-role.hcl"
}
