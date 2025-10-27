# -----------------------------------------------------------------------------
# PRODUCTION - US-EAST-1 - GENERAL NETWORKING
# -----------------------------------------------------------------------------

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "general_networking" {
  path = "${get_repo_root()}/_env_helpers/general-networking.hcl"
}
