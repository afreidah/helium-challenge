# -----------------------------------------------------------------------------
# SECRETS MANAGER - STAGING ENVIRONMENT CONFIGURATION
# -----------------------------------------------------------------------------
#
# This file configures AWS Secrets Manager for the staging environment.
# Staging has a shorter recovery window (7 days vs 30 days in production).
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "secrets_manager" {
  path = "${get_repo_root()}/_env_helpers/secrets-manager.hcl"
}

# No environment-specific overrides needed - configuration comes from root.hcl
