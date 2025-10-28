# -----------------------------------------------------------------------------
# EKS NODE GROUP ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
#
# This file provides environment-specific configuration for EKS node groups.
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
#   include "eks_node_group" {
#     path = "${get_repo_root()}/_env_helpers/eks-node-group.hcl"
#   }
#
# Configuration:
#   - All node group settings come from root.hcl eks_cluster_config.node_groups_defaults
#
# Directory Structure:
#   <environment>/<region>/eks-node-group/terragrunt.hcl
#   Example: production/us-east-1/eks-node-group/terragrunt.hcl
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/eks-node-group"
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

dependency "general_networking" {
  config_path = "../general-networking"

  mock_outputs = {
    vpc_id                 = "vpc-12345678"
    private_app_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "eks_cluster" {
  config_path = "../eks-cluster"

  mock_outputs = {
    cluster_name                       = "mock-cluster"
    cluster_version                    = "1.31"
    cluster_endpoint                   = "https://MOCK1234567890ABCDEF.gr7.us-east-1.eks.amazonaws.com"
    cluster_certificate_authority_data = "LS0tLS1CRUdJTiBDRVJUSUZJQ0FURS0tLS0tCk1JSUN5RENDQWJDZ0F3SUJBZ0lCQURBTkJna3Foa2lHOXcwQkFRc0ZBREFWTVJNd0VRWURWUVFERXdwcmRXSmwKY201bGRHVnpNQjRYRFRJeE1EWXdOVEUxTXpZd05Gb1hEVE14TURZd016RTFNell3TkZvd0ZURVRNQkVHQTFVRQpBeE1LYTNWaVpYSnVaWFJsY3pDQ0FTSXdEUVlKS29aSWh2Y05BUUVCQlFBRGdnRVBBRENDQVFvQ2dnRUJBTHNHCmV4cUxqWGIxOU1JZVNBYkJGV0Q4Zz09Ci0tLS0tRU5EIENFUlRJRklDQVRFLS0tLS0K"
    cluster_security_group_id          = "sg-mock1234567890abc"
    node_security_group_id             = "sg-mock1234567890def"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # Node group identification
  node_group_name = "${local.root.inputs.environment}-${local.root.inputs.region}-eks-nodes"

  # Cluster identification and connection
  cluster_name                       = dependency.eks_cluster.outputs.cluster_name
  cluster_version                    = dependency.eks_cluster.outputs.cluster_version
  cluster_endpoint                   = dependency.eks_cluster.outputs.cluster_endpoint
  cluster_certificate_authority_data = dependency.eks_cluster.outputs.cluster_certificate_authority_data
  cluster_security_group_id          = dependency.eks_cluster.outputs.cluster_security_group_id

  # Networking
  vpc_id     = dependency.general_networking.outputs.vpc_id
  subnet_ids = dependency.general_networking.outputs.private_app_subnet_ids

  # Node group configuration from root.hcl eks_cluster_config.node_groups_defaults
  ami_type       = local.root.inputs.eks_cluster_config.node_groups_defaults.ami_type
  capacity_type  = local.root.inputs.eks_cluster_config.node_groups_defaults.capacity_type
  disk_size      = local.root.inputs.eks_cluster_config.node_groups_defaults.disk_size
  instance_types = local.root.inputs.eks_cluster_config.node_groups_defaults.instance_types
  desired_size   = local.root.inputs.eks_cluster_config.node_groups_defaults.desired_size
  min_size       = local.root.inputs.eks_cluster_config.node_groups_defaults.min_size
  max_size       = local.root.inputs.eks_cluster_config.node_groups_defaults.max_size

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
