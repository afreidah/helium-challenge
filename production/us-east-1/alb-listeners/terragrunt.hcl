# -----------------------------------------------------------------------------
# ALB LISTENERS
# -----------------------------------------------------------------------------
# Creates HTTP/HTTPS listeners that attach to the ALB and route traffic to
# target groups. Listeners define how the ALB accepts and processes incoming
# traffic on specific ports.
#
# Configuration:
#   - Listener defaults defined in root.hcl (listeners, listener_rules)
#   - Environment-specific overrides via inputs merge (if needed)
#   - Certificate ARN must be provided for HTTPS listener
#
# Dependencies:
#   - alb (load balancer to attach listeners to)
#   - alb-target-groups (target groups for routing)
#
# Outputs:
#   - http_listener_arn: HTTP listener ARN
#   - https_listener_arn: HTTPS listener ARN
#   - listener_rule_arns: Map of rule names to ARNs
#
# Common Patterns:
#   - HTTP → HTTPS redirect (default from root.hcl)
#   - Path-based routing (/api/* → api target group)
#   - Host-based routing (app1.domain.com → app1 target group)
#   - Fixed response for maintenance mode
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "alb_listeners" {
  path = "${get_repo_root()}/_env_helpers/alb-listeners.hcl"
}
