include "root" {
  path = find_in_parent_folders("root.hcl")
}

include "aurora_postgresql" {
  path   = "${get_repo_root()}/_env_helpers/aurora-test-exact-copy.hcl"
}
