# -----------------------------------------------------------------------------
# SECRETS MANAGER - ENVIRONMENT CONFIGURATION
# -----------------------------------------------------------------------------
#
# This file configures AWS Secrets Manager for storing sensitive credentials
# including Aurora database passwords and application secrets. Secrets are
# encrypted using KMS and can be read by EKS pods via IAM roles.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "secrets_manager" {
  path = "${get_repo_root()}/_env_helpers/secrets-manager.hcl"
}
