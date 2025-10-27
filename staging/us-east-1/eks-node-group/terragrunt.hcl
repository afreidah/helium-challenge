# -----------------------------------------------------------------------------
# PRODUCTION EKS NODE GROUP
# -----------------------------------------------------------------------------
#
# Production EKS worker node group configuration
# Location: production/us-east-1/eks-node-group/terragrunt.hcl
#
# Configuration:
#   - Imports environment helper for standard node group setup
#   - Inherits all node group settings from root.hcl
#   - No environment-specific overrides needed (all in root.hcl)
#
# Node Group Settings (from root.hcl):
#   - Instance Type: t3.large (production) / t3.medium (staging)
#   - Min Size: 2 nodes (production) / 1 node (staging)
#   - Desired Size: 3 nodes (production) / 2 nodes (staging)
#   - Max Size: 10 nodes (production) / 5 nodes (staging)
#   - Disk: 50GB gp3, encrypted
#   - IMDSv2: Required
#   - Update Strategy: Max 33% unavailable
#   - Labels: environment and workload
# -----------------------------------------------------------------------------

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "eks_node_group" {
  path = "${get_repo_root()}/_env_helpers/eks-node-group.hcl"
}
