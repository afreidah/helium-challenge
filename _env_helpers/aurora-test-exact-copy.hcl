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
  skip_outputs = true

  mock_outputs = {
    vpc_id             = "vpc-12345678"
    private_subnet_ids = ["subnet-12345678", "subnet-87654321"]
  }
}

dependency "kms" {
  config_path  = "../kms"
  skip_outputs = true

  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    key_id  = "12345678-1234-1234-1234-123456789012"
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # Cluster name from environment/region/component
  cluster_name = "${local.root.locals.environment}-${local.root.locals.region}-eks"

  # VPC and networking from dependency
  vpc_id     = dependency.general_networking.outputs.vpc_id
  subnet_ids = dependency.general_networking.outputs.private_subnet_ids

  # Encryption from KMS dependency
  cluster_encryption_key_arn = dependency.kms.outputs.key_arn
  cloudwatch_kms_key_id      = dependency.kms.outputs.key_id

  # EKS configuration from root.hcl
  kubernetes_version        = local.root.inputs.eks_kubernetes_version
  endpoint_private_access   = local.root.inputs.eks_endpoint_private_access
  endpoint_public_access    = local.root.inputs.eks_endpoint_public_access
  public_access_cidrs       = local.root.inputs.eks_public_access_cidrs
  enabled_cluster_log_types = local.root.inputs.eks_enabled_cluster_log_types
  cloudwatch_retention_days = local.root.inputs.eks_cloudwatch_retention_days

  # Add-on versions from root.hcl
  vpc_cni_version    = lookup(local.root.inputs, "eks_vpc_cni_version", null)
  coredns_version    = lookup(local.root.inputs, "eks_coredns_version", null)
  kube_proxy_version = lookup(local.root.inputs, "eks_kube_proxy_version", null)

  # AWS auth ConfigMap (will be configured after node group is created)
  manage_aws_auth_configmap = false
  node_security_group_id    = null

  # Tags from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
