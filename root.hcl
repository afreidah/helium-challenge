# -----------------------------------------------------------------------------
# TERRAGRUNT ROOT CONFIGURATION
# -----------------------------------------------------------------------------
#
# This root configuration file provides dynamic environment detection and
# shared configuration for all Terragrunt modules in this repository.
#
# Directory Structure:
#   <environment>/<region>/<component>/terragrunt.hcl
#   Example: production/us-east-1/eks-cluster/terragrunt.hcl
#
# Automatic Path Parsing:
#   - environment: Extracted from first path component (production, staging)
#   - region: Extracted from second path component (us-east-1, us-west-2, etc)
#   - component: Extracted from third path component (vpc, eks-cluster, etc)
#
# Features:
#   - Dynamic backend configuration per environment
#   - Automatic AWS provider configuration
#   - Environment-specific defaults (instance sizes, replica counts)
#   - Consistent tagging across all resources
#   - Resource naming with environment/region/component prefix
#
# Generated Files:
#   - backend.tf: Local backend configuration
#   - provider.tf: AWS provider with default tags
#
# IMPORTANT:
#   - Currently using local backend for development
#   - Uses AWS credentials from environment variables or ~/.aws/credentials
# -----------------------------------------------------------------------------

locals {
  # -----------------------------------------------------------------------------
  # Path Parsing (portable across Terragrunt versions)
  # -----------------------------------------------------------------------------

  repo_root = abspath(get_repo_root())
  workdir   = abspath(get_original_terragrunt_dir())

  # Compute path of the invoking module relative to repo root by index math
  relative_path = substr(
    local.workdir,
    length(local.repo_root) + 1,
    length(local.workdir) - (length(local.repo_root) + 1)
  )

  # Parse directory structure: <environment>/<region>/<component>
  path_components = split("/", local.relative_path)
  environment     = length(local.path_components) > 0 ? local.path_components[0] : ""
  region          = length(local.path_components) > 1 ? local.path_components[1] : ""
  component       = length(local.path_components) > 2 ? local.path_components[2] : ""

  # -----------------------------------------------------------------------------
  # Environment-Specific Configuration (BUSINESS LOGIC)
  # -----------------------------------------------------------------------------

  env_config = {
    # --- Production Environment ---
    production = {
      instance_type = "t3.large"
      replica_count = 3

      # >>> AZ selection per environment <<<
      # Use ["a","b"] for 2 AZs; use ["a","b","c"] for 3 AZs
      az_suffixes = ["a", "b"]

      # Networking CIDRs (per-environment)
      vpc_cidr = "10.0.0.0/16"

      public_subnet_cidrs = [
        "10.0.1.0/24", # AZ-a
        "10.0.2.0/24", # AZ-b
        # "10.0.3.0/24",  # AZ-c (uncomment if using 3 AZs)
      ]

      private_app_subnet_cidrs = [
        "10.0.16.0/20", # AZ-a
        "10.0.32.0/20", # AZ-b
        # "10.0.48.0/20",  # AZ-c (uncomment if using 3 AZs)
      ]

      private_data_subnet_cidrs = [
        "10.0.4.0/24", # AZ-a
        "10.0.5.0/24", # AZ-b
        # "10.0.6.0/24",  # AZ-c (uncomment if using 3 AZs)
      ]
    }

    # --- Staging Environment ---
    staging = {
      instance_type = "t3.medium"
      replica_count = 2

      # >>> AZ selection per environment <<<
      az_suffixes = ["a", "b"]

      # Example distinct CIDRs for staging (adjust to your plan)
      vpc_cidr = "10.1.0.0/16"

      public_subnet_cidrs = [
        "10.1.1.0/24", # AZ-a
        "10.1.2.0/24", # AZ-b
        # "10.1.3.0/24",  # AZ-c (uncomment if using 3 AZs)
      ]

      private_app_subnet_cidrs = [
        "10.1.16.0/20", # AZ-a
        "10.1.32.0/20", # AZ-b
        # "10.1.48.0/20",  # AZ-c (uncomment if using 3 AZs)
      ]

      private_data_subnet_cidrs = [
        "10.1.4.0/24", # AZ-a
        "10.1.5.0/24", # AZ-b
        # "10.1.6.0/24",  # AZ-c (uncomment if using 3 AZs)
      ]
    }
  }

  # -------------------------------------------------------------------------
  # Security group rule definitions by component
  # -------------------------------------------------------------------------

  security_group_rules = {
    # --- APPLICATION LOAD BALANCER ---
    alb = {
      name_suffix = "alb"
      description = "Security group for Application Load Balancer"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow HTTPS from internet"
        },
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow HTTP from internet"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound to EKS nodes"
        }
      ]
    }

    # --- EKS CLUSTER CONTROL PLANE ---
    eks_cluster = {
      name_suffix = "eks-cluster"
      description = "Security group for EKS cluster control plane"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "Allow HTTPS from VPC (for kubectl access)"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }

    # --- EKS WORKER NODES ---
    eks_nodes = {
      name_suffix = "eks-nodes"
      description = "Security group for EKS worker nodes"
      ingress_rules = [
        {
          from_port   = 0
          to_port     = 65535
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "Allow all TCP from VPC (for ALB and cluster communication)"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "Allow all outbound"
        }
      ]
    }

    # --- AURORA POSTGRESQL ---
    aurora = {
      name_suffix = "aurora-postgresql"
      description = "Security group for Aurora PostgreSQL cluster"
      ingress_rules = [
        {
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "Allow PostgreSQL from VPC (EKS nodes)"
        }
      ]
      egress_rules = []
    }
  }

  # -------------------------------------------------------------------------
  # IAM role configurations by component
  # -------------------------------------------------------------------------

  iam_role_configs = {
    # --- EKS CLUSTER ROLE ---
    eks_cluster = {
      name_suffix = "eks-cluster-role"
      description = "IAM role for EKS cluster control plane"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "eks.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
      ]
      create_instance_profile = false
    }

    # --- EKS NODE ROLE ---
    eks_node = {
      name_suffix = "eks-node-role"
      description = "IAM role for EKS worker nodes"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [
          {
            Effect = "Allow"
            Principal = {
              Service = "ec2.amazonaws.com"
            }
            Action = "sts:AssumeRole"
          }
        ]
      })
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
      create_instance_profile = true
    }
  }

  # Cross-Environment Shared Defaults (STATIC)
  enable_nat_gateway = true
  single_nat_gateway = false

  # Resource name prefix
  name_prefix = "${local.environment}-${local.region}-${local.component}"

  # Availability Zones (computed directly from env_config)
  availability_zones = [
    for s in local.env_config[local.environment].az_suffixes : "${local.region}${s}"
  ]
}

# -----------------------------------------------------------------------------
# BACKEND CONFIGURATION
# -----------------------------------------------------------------------------

generate "backend" {
  path      = "backend.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
terraform {
  backend "local" {
    path = "terraform.tfstate"
  }
}
EOF
}

# -----------------------------------------------------------------------------
# Generate Files
# -----------------------------------------------------------------------------

generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = {
      Environment = "${local.environment}"
      Region      = "${local.region}"
      Component   = "${local.component}"
      ManagedBy   = "Terragrunt"
      Terraform   = "true"
    }
  }
}
EOF
}

generate "checkov_config" {
  path      = ".checkov.yaml"
  if_exists = "overwrite"
  contents  = <<EOF
skip-check:
  - CKV_AWS_130  # Public subnets intentionally assign IPs
  - CKV2_AWS_11  # Flow logs handled elsewhere
  - CKV2_AWS_12  # Default SG behavior intentionally managed
  - CKV2_AWS_5   # Security groups created before resources that use them
EOF
}

generate "trivy_ignore" {
  path      = ".trivyignore"
  if_exists = "overwrite"
  contents  = <<EOF
# Ignore: Public subnets intentionally assign public IPs for NAT gateways
AVD-AWS-0164

# Ignore: Flow logs handled externally (outside of Terraform)
AVD-AWS-0178

# Ignore: Egress to internet required for EKS nodes, package updates, and AWS service access
AVD-AWS-0104
EOF
}

# -----------------------------------------------------------------------------
# TERRAFORM EXECUTION SETTINGS & HOOKS
# -----------------------------------------------------------------------------
# - Forces all `plan` runs to write a named plan file we can inspect.
# - AFTER HOOK (on plan): render JSON plan and run Checkov against it.

terraform {
  # Always write a named plan so we can render it to JSON
  extra_arguments "force_named_plan_out" {
    commands  = ["plan"]
    arguments = ["-out=plan.tfplan"]
  }

  after_hook "trivy_scan" {
    commands = ["plan", "apply"]
    execute = [
      "bash", "-c",
      "echo 'Running Trivy config scan...'; trivy config ."
    ]
  }

  after_hook "checkov_scan" {
    commands = ["plan", "apply"]
    execute = [
      "bash", "-c",
      "echo 'Running Checkov...'; checkov -d . --compact"
    ]
  }
}

# -----------------------------------------------------------------------------
# COMMON INPUTS
# -----------------------------------------------------------------------------

inputs = {
  # Core identity
  environment = local.environment
  region      = local.region
  component   = local.component
  name_prefix = local.name_prefix

  # Compute/capacity
  instance_type = local.env_config[local.environment].instance_type
  replica_count = local.env_config[local.environment].replica_count

  # Networking — per-environment values from env_config
  vpc_name                  = "${local.environment}"
  vpc_cidr                  = local.env_config[local.environment].vpc_cidr
  public_subnet_cidrs       = local.env_config[local.environment].public_subnet_cidrs
  private_app_subnet_cidrs  = local.env_config[local.environment].private_app_subnet_cidrs
  private_data_subnet_cidrs = local.env_config[local.environment].private_data_subnet_cidrs

  # Networking — shared/static defaults computed here
  availability_zones = local.availability_zones
  enable_nat_gateway = local.enable_nat_gateway
  single_nat_gateway = local.single_nat_gateway

  # Security group rules from locals
  security_group_rules = local.security_group_rules

  # IAM role configs from locals
  iam_role_configs = local.iam_role_configs

  # Common tags
  common_tags = {
    Environment = local.environment
    Region      = local.region
    Component   = local.component
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }
}
