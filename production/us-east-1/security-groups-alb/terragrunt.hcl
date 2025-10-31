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
