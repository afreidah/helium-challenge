# -----------------------------------------------------------------------------
# ALB - APPLICATION LOAD BALANCER
# -----------------------------------------------------------------------------
# Creates an Application Load Balancer for HTTP/HTTPS traffic distribution.
# The ALB is created without listeners or target groups - those are managed
# by separate alb-listeners and alb-target-groups components.
#
# Configuration:
#   - ALB settings defined in root.hcl (alb_config_defaults)
#   - Environment-specific overrides via inputs merge (if needed)
#
# Dependencies:
#   - general-networking (VPC, subnets)
#   - security-groups-alb (ALB security group)
#
# Outputs:
#   - alb_arn: Load balancer ARN for listener attachment
#   - alb_dns_name: DNS endpoint for Route53 records
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "alb" {
  path = "${get_repo_root()}/_env_helpers/alb.hcl"
}
