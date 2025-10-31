# -----------------------------------------------------------------------------
# SECURITY GROUP - EKS CLUSTER CONTROL PLANE
# -----------------------------------------------------------------------------
# Creates security group for the EKS cluster control plane with rules allowing
# HTTPS traffic from the VPC for kubectl access.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security_groups" {
  path = "${get_repo_root()}/_env_helpers/security-groups.hcl"
}
