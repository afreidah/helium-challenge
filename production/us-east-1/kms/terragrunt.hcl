# -----------------------------------------------------------------------------
# PRODUCTION - US-EAST-1 - KMS
# -----------------------------------------------------------------------------

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "kms" {
  path = "${get_repo_root()}/_env_helpers/kms.hcl"
}
