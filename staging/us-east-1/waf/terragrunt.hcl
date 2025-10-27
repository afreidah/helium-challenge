# -----------------------------------------------------------------------------
# PRODUCTION WAF
# -----------------------------------------------------------------------------
#
# Production AWS WAF WebACL configuration
# Location: production/us-east-1/waf/terragrunt.hcl
#
# Configuration:
#   - Imports environment helper for standard WAF setup
#   - Inherits all WAF settings from root.hcl
#   - No environment-specific overrides needed (all in root.hcl)
#
# WAF Settings (from root.hcl):
#   - Scope: REGIONAL (for ALB)
#   - AWS Managed Rules: Enabled
#   - Rate Limiting: Enabled (2000 req/5min in prod, 1000 in staging)
#   - IP Reputation Blocking: Enabled
#   - Geographic Blocking: Disabled by default
#   - CloudWatch Metrics: Enabled
#   - Sampled Requests: Enabled
# -----------------------------------------------------------------------------

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "waf" {
  path = "${get_repo_root()}/_env_helpers/waf.hcl"
}
