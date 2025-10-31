# -----------------------------------------------------------------------------
# AURORA POSTGRESQL
# -----------------------------------------------------------------------------
# Creates Aurora PostgreSQL cluster with configuration from root.hcl.
# All settings (instance class, backup retention, monitoring) are environment-
# specific and defined in root.hcl aurora_config.
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aurora_postgresql" {
  path = "${get_repo_root()}/_env_helpers/aurora-postgresql.hcl"
}
