# -----------------------------------------------------------------------------
# SECURITY GROUP - EKS WORKER NODES
# -----------------------------------------------------------------------------
# Creates security group for EKS worker nodes with rules allowing all TCP
# traffic from the VPC for ALB and cluster communication.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security_groups" {
  path = "${get_repo_root()}/_env_helpers/security-groups.hcl"
}
