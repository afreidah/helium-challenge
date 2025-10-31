# -----------------------------------------------------------------------------
# ALB TARGET GROUPS
# -----------------------------------------------------------------------------
# Creates target groups for routing ALB traffic to backend instances or IPs.
# Target groups are independent of the ALB and can be registered with EKS
# nodes, EC2 instances, IP addresses, or Lambda functions.
#
# Configuration:
#   - Target group definitions in this file's inputs block
#   - Health check defaults from root.hcl (if defined)
#   - Environment-specific settings (port, protocol, target_type)
#
# Dependencies:
#   - general-networking (VPC for target group creation)
#
# Outputs:
#   - target_group_arns: Map of target group names to ARNs
#   - target_group_names: Map for reference in other components
#
# Target Types:
#   - instance: EC2 instances (use for EKS worker nodes)
#   - ip: IP addresses (use for EKS pods with AWS VPC CNI)
#   - lambda: Lambda function ARNs
#   - alb: Another ALB ARN
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "alb_target_groups" {
  path = "${get_repo_root()}/_env_helpers/alb-target-groups.hcl"
}
