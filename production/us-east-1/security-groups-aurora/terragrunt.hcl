# -----------------------------------------------------------------------------
# SECURITY GROUP - AURORA POSTGRESQL
# -----------------------------------------------------------------------------
# Creates security group for Aurora PostgreSQL cluster with rules allowing
# PostgreSQL traffic from the VPC (EKS nodes only).
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "security_groups" {
  path = "${get_repo_root()}/_env_helpers/security-groups.hcl"
}
