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
#   - All WAF settings come from root.hcl waf_config
#
# Directory Structure:
#   <environment>/<region>/waf/terragrunt.hcl
#   Example: production/us-east-1/waf/terragrunt.hcl
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/waf"
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # All WAF configuration from root.hcl waf_config
  name              = local.root.inputs.waf_config.name
  description       = local.root.inputs.waf_config.description
  scope             = local.root.inputs.waf_config.scope
  rules             = local.root.inputs.waf_config.rules
  default_action    = local.root.inputs.waf_config.default_action
  visibility_config = local.root.inputs.waf_config.visibility_config

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
