# -----------------------------------------------------------------------------
# IAM ROLE ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates an IAM role with configuration defined in root.hcl.
# Automatically handles both regular IAM roles and IRSA roles.
#
# Supported Components:
#   - iam-role-eks-cluster: EKS control plane role
#   - iam-role-eks-node: EKS worker node role  
#   - iam-role-external-secrets: External Secrets Operator with IRSA
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/iam-role"
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  root      = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  component = local.root.locals.component

  # Map component names to their config keys in root.hcl
  role_config_map = {
    "iam-role-eks-cluster"      = "eks_cluster"
    "iam-role-eks-node"         = "eks_node"
    "iam-role-external-secrets" = "external_secrets"
  }

  # IRSA configuration for roles that need OIDC trust policies
  irsa_config_map = {
    "iam-role-external-secrets" = {
      namespace = "external-secrets"
      sa_name   = "external-secrets-sa"
    }
  }

  # Get the config key and base config from root.hcl
  config_key  = lookup(local.role_config_map, local.component, null)
  base_config = local.config_key != null ? local.root.locals.iam_role_configs[local.config_key] : null

  # Determine if this component needs IRSA
  needs_irsa  = contains(keys(local.irsa_config_map), local.component)
  irsa_config = local.needs_irsa ? local.irsa_config_map[local.component] : null
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------
# Always define dependency, but it's only used by IRSA roles
# This avoids Terragrunt evaluation issues with conditional dependencies

dependency "eks" {
  config_path = local.needs_irsa ? "../eks-cluster" : "${get_repo_root()}"
  
  # Skip outputs if not needed to avoid loading state
  skip_outputs = !local.needs_irsa

  mock_outputs = {
    cluster_name      = "mock-cluster"
    oidc_provider_arn = "arn:aws:iam::123456789012:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/MOCK"
    oidc_provider     = "oidc.eks.us-east-1.amazonaws.com/id/MOCK"
  }
  mock_outputs_allowed_terraform_commands = ["validate", "plan", "init"]
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # For IRSA roles: merge base config with OIDC trust policy
  # For regular roles: use base config as-is
  role_config = local.needs_irsa ? merge(
    local.base_config,
    {
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Federated = dependency.eks.outputs.oidc_provider_arn
            }
            Action = "sts:AssumeRoleWithWebIdentity"
            Condition = {
              StringEquals = {
                "${dependency.eks.outputs.oidc_provider}:sub" = "system:serviceaccount:${local.irsa_config.namespace}:${local.irsa_config.sa_name}"
                "${dependency.eks.outputs.oidc_provider}:aud" = "sts.amazonaws.com"
              }
            }
          }
        ]
      })
    }
  ) : local.base_config
}
