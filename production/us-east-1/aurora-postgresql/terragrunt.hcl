# -----------------------------------------------------------------------------
# AURORA POSTGRESQL CLUSTER
# -----------------------------------------------------------------------------
#
# This environment deploys an Aurora PostgreSQL cluster with multiple instances,
# automated backups, encryption, and high availability.
#
# Path: environments/<env>/<region>/aurora-postgresql/terragrunt.hcl
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aurora_postgresql" {
  path   = "${get_repo_root()}/_env_helpers/aurora-postgresql.hcl"
  expose = true
}
