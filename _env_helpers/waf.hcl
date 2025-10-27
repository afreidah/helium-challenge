# -----------------------------------------------------------------------------
# WAF ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
#
# This file provides environment-specific configuration for AWS WAF WebACL.
# It follows the standard pattern used across all infrastructure components.
#
# Usage:
#   Include this file in environment-specific terragrunt.hcl files:
#
#   include "root" {
#     path   = find_in_parent_folders("root.hcl")
#     expose = true
#   }
#
#   include "waf" {
#     path = "${get_repo_root()}/_env_helpers/waf.hcl"
#   }
#
# Configuration:
#   - Adds WAF specific configuration
#   - All WAF settings come from root.hcl with prod/staging switches
#
# Directory Structure:
#   <environment>/<region>/waf/terragrunt.hcl
#   Example: production/us-east-1/waf/terragrunt.hcl
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# TERRAFORM SOURCE
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules//waf"
}

# -----------------------------------------------------------------------------
# LOCALS
# -----------------------------------------------------------------------------

locals {
  root_config = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  waf_config  = local.root_config.locals.waf_config
}

# -----------------------------------------------------------------------------
# INPUTS
# -----------------------------------------------------------------------------

inputs = {
  # WAF configuration from root.hcl
  name                       = local.waf_config.name
  scope                      = local.waf_config.scope
  default_action             = local.waf_config.default_action
  enable_aws_managed_rules   = local.waf_config.enable_aws_managed_rules
  enable_rate_limiting       = local.waf_config.enable_rate_limiting
  rate_limit                 = local.waf_config.rate_limit
  enable_geo_blocking        = local.waf_config.enable_geo_blocking
  blocked_countries          = local.waf_config.blocked_countries
  enable_ip_reputation       = local.waf_config.enable_ip_reputation
  cloudwatch_metrics_enabled = local.waf_config.cloudwatch_metrics_enabled
  sampled_requests_enabled   = local.waf_config.sampled_requests_enabled

  # Tags will be passed automatically from root.hcl inputs
}
