# -----------------------------------------------------------------------------
# EKS CLUSTER ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates an EKS cluster with configuration defined in root.hcl
# and dependencies on general-networking and kms.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/eks-cluster"
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
  config_path  = "../general-networking"
  # Remove skip_outputs = true

  mock_outputs = {
    vpc_id                 = "vpc-12345678"
    private_app_subnet_ids = ["subnet-12345678", "subnet-87654321"]  # Fixed name
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "kms" {
  config_path  = "../kms"
  # Remove skip_outputs = true

  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    key_id  = "12345678-1234-1234-1234-123456789012"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # Cluster name from environment/region/component
  cluster_name = "${local.root.inputs.environment}-${local.root.inputs.region}-eks"

  # VPC and networking from dependency
  vpc_id     = dependency.general_networking.outputs.vpc_id
  subnet_ids = dependency.general_networking.outputs.private_app_subnet_ids

  # Encryption from KMS dependency
  cluster_encryption_key_arn = dependency.kms.outputs.key_arn
  cloudwatch_kms_key_id      = dependency.kms.outputs.key_id

  # EKS configuration from root.hcl eks_cluster_config
  kubernetes_version                          = local.root.inputs.eks_cluster_config.kubernetes_version
  endpoint_private_access                     = local.root.inputs.eks_cluster_config.endpoint_private_access
  endpoint_public_access                      = local.root.inputs.eks_cluster_config.endpoint_public_access
  public_access_cidrs                         = local.root.inputs.eks_cluster_config.public_access_cidrs
  enabled_cluster_log_types                   = local.root.inputs.eks_cluster_config.enabled_cluster_log_types
  cloudwatch_retention_days                   = local.root.inputs.eks_cluster_config.cloudwatch_retention_days
  authentication_mode                         = local.root.inputs.eks_cluster_config.authentication_mode
  bootstrap_cluster_creator_admin_permissions = local.root.inputs.eks_cluster_config.bootstrap_cluster_creator_admin_permissions
  enable_cluster_logging                      = local.root.inputs.eks_cluster_config.enable_cluster_logging
  enable_pod_identity_agent                   = local.root.inputs.eks_cluster_config.enable_pod_identity_agent
  pod_identity_agent_version                  = local.root.inputs.eks_cluster_config.pod_identity_agent_version

  # Add-on versions from root.hcl eks_cluster_config
  vpc_cni_version    = local.root.inputs.eks_cluster_config.vpc_cni_version
  coredns_version    = local.root.inputs.eks_cluster_config.coredns_version
  kube_proxy_version = local.root.inputs.eks_cluster_config.kube_proxy_version

  # Encryption configuration from root.hcl eks_cluster_config
  encryption_config = local.root.inputs.eks_cluster_config.encryption_config

  # AWS auth ConfigMap (will be configured after node group is created)
  manage_aws_auth_configmap = false
  node_security_group_id    = null

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
