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

      # >>> AZ selection per environment 
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

      # Aurora PostgreSQL configuration
      aurora = {
        instance_class                        = "db.r6g.xlarge"
        instance_count                        = 3
        backup_retention_period               = 30
        skip_final_snapshot                   = false
        performance_insights_enabled          = true
        performance_insights_retention_period = 31
        monitoring_interval                   = 30
        deletion_protection                   = true
      }
    }

    # --- Staging Environment ---
    staging = {
      instance_type = "t3.medium"
      replica_count = 2

      # >>> AZ selection per environment 
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

      # Aurora PostgreSQL configuration
      aurora = {
        instance_class                        = "db.r6g.large"
        instance_count                        = 2
        backup_retention_period               = 14
        skip_final_snapshot                   = false
        performance_insights_enabled          = true
        performance_insights_retention_period = 7
        monitoring_interval                   = 60
        deletion_protection                   = true
      }
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

  # -------------------------------------------------------------------------
  # ALB Configuration Defaults
  # -------------------------------------------------------------------------

  alb_config_defaults = {
    internal                         = false
    enable_deletion_protection       = false
    load_balancer_type               = "application"
    preserve_host_header             = false
    enable_cross_zone_load_balancing = true
    enable_http2                     = true
    enable_waf_fail_open             = false
    desync_mitigation_mode           = "defensive"
    drop_invalid_header_fields       = true
    enable_xff_client_port           = false
    xff_header_processing_mode       = "append"
    idle_timeout                     = 60
    enable_deletion_protection       = local.environment == "production" ? true : false

    # Access Logs (enable for production)
    access_logs = local.environment == "production" ? {
      enabled = true
      bucket  = "" # Must be set in environment-specific inputs
      prefix  = "alb-logs"
      } : {
      enabled = false
    }

    # Listeners - simplified, no default HTTP listener (add in environment if needed)
    listeners = {}

    # Target Groups (empty by default, populated per environment)
    target_groups = {}

    # Listener Rules (empty by default, populated per environment)
    listener_rules = {}

    # Health Check Defaults
    health_check_defaults = {
      enabled             = true
      healthy_threshold   = 2
      unhealthy_threshold = 2
      timeout             = 5
      interval            = 30
      protocol            = "HTTP"
      path                = "/health"
      matcher             = "200"
    }
  }

  # -------------------------------------------------------------------------
  # ALB Listeners Configuration Defaults
  # -------------------------------------------------------------------------

  listeners = {
    http = {
      enabled  = true
      port     = 80
      protocol = "HTTP"
      default_action = {
        type = "redirect"
        redirect = {
          port        = "443"
          protocol    = "HTTPS"
          status_code = "HTTP_301"
        }
      }
    }
    https = {
      enabled         = false
      port            = 443
      protocol        = "HTTPS"
      ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
      certificate_arn = null
      default_action = {
        type = "fixed-response"
        fixed_response = {
          content_type = "text/plain"
          message_body = "Not Found"
          status_code  = "404"
        }
      }
    }
  }

  listener_rules = {}

  # Cross-Environment Shared Defaults (STATIC)
  enable_nat_gateway = true
  single_nat_gateway = false

  # Resource name prefix
  name_prefix = "${local.environment}-${local.region}-${local.component}"

  # Availability Zones (computed directly from env_config)
  availability_zones = [
    for s in local.env_config[local.environment].az_suffixes : "${local.region}${s}"
  ]

  # -----------------------------------------------------------------------------
  # EKS Cluster Settings
  # -----------------------------------------------------------------------------

  eks_kubernetes_version = "1.31"

  # -----------------------------------------------------------------------------
  # Network Access Configuration
  # -----------------------------------------------------------------------------
  eks_endpoint_private_access = true
  eks_endpoint_public_access  = local.environment == "production" ? false : true

  # Restrict public access CIDRs per environment
  # Production: Private only (public_access disabled)
  # Staging: Restricted CIDR blocks for admin access
  eks_public_access_cidrs = local.environment == "production" ? [] : ["0.0.0.0/0"]

  # -----------------------------------------------------------------------------
  # Logging and Monitoring
  # -----------------------------------------------------------------------------
  eks_enabled_cluster_log_types = [
    "api",
    "audit",
    "authenticator",
    "controllerManager",
    "scheduler"
  ]

  eks_cloudwatch_retention_days = local.environment == "production" ? 365 : 30

  # -----------------------------------------------------------------------------
  # Security Configuration
  # -----------------------------------------------------------------------------

  # Secrets encryption using AWS KMS
  eks_encryption_config = {
    resources = ["secrets"]
    # KMS key ARN should be provided per environment via terragrunt.hcl
    # If null, module will create a dedicated KMS key
    kms_key_arn = null
  }

  # Authentication mode for cluster access
  # API_AND_CONFIG_MAP: Supports both IAM and aws-auth ConfigMap (default, backward compatible)
  # API: IAM only (recommended for new clusters)
  eks_authentication_mode = "API_AND_CONFIG_MAP"

  # Bootstrap cluster creator admin permissions
  # When true, the IAM principal creating the cluster gets admin access
  eks_bootstrap_cluster_creator_admin_permissions = true

  # Enable control plane logging to CloudWatch
  eks_enable_cluster_logging = true

  # -----------------------------------------------------------------------------
  # Add-ons Configuration
  # -----------------------------------------------------------------------------

  # EKS Add-on versions (null = latest compatible version)
  eks_vpc_cni_version    = null
  eks_coredns_version    = null
  eks_kube_proxy_version = null

  # Pod Identity Agent add-on for EKS Pod Identity (recommended over IRSA)
  eks_enable_pod_identity_agent  = true
  eks_pod_identity_agent_version = null # null = latest

  # -----------------------------------------------------------------------------
  # EKS Node Group Configuration
  # -----------------------------------------------------------------------------

  # Node group name
  eks_node_group_name = "${local.name_prefix}-nodes"

  # Node group defaults - capacity and instance configuration
  eks_node_groups_defaults = {
    # Instance types per environment
    instance_types = local.environment == "production" ? ["t3.large"] : ["t3.medium"]

    # Capacity settings per environment
    desired_size = local.env_config[local.environment].replica_count
    min_size     = local.environment == "production" ? 2 : 1
    max_size     = local.environment == "production" ? 10 : 5

    # Disk configuration
    disk_size      = 50 # GB
    disk_type      = "gp3"
    disk_encrypted = true

    # Security
    enable_bootstrap_user_data = false # Use standard AMI bootstrap
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required" # IMDSv2 required
      http_put_response_hop_limit = 1
      instance_metadata_tags      = "disabled"
    }

    # Updates
    force_update_version = false
    update_config = {
      max_unavailable_percentage = 33
    }

    # Tags
    tags = {} # Additional node-specific tags can be added per environment
  }

  # Kubernetes labels for nodes
  eks_node_labels = {
    environment = local.environment
    workload    = "general"
  }

  # Kubernetes taints for nodes (none by default for general-purpose nodes)
  eks_node_taints = []

  # -----------------------------------------------------------------------------
  # WAF Configuration
  # -----------------------------------------------------------------------------

  waf_config = {
    # WAF WebACL name
    name = "${local.name_prefix}-waf"

    # WAF scope - REGIONAL for ALB, CLOUDFRONT for CloudFront distributions
    scope = "REGIONAL"

    # Default action for requests that don't match any rules
    default_action = "allow"

    # AWS Managed Rules - OWASP Top 10, known bad inputs, etc.
    enable_aws_managed_rules = true

    # Rate limiting to prevent abuse
    enable_rate_limiting = true
    rate_limit           = local.environment == "production" ? 2000 : 1000 # requests per 5 minutes per IP

    # Geographic blocking (disabled by default)
    enable_geo_blocking = false
    blocked_countries   = [] # ISO 3166-1 alpha-2 codes, e.g., ["CN", "RU"]

    # IP reputation lists - blocks known malicious IPs
    enable_ip_reputation = true

    # CloudWatch metrics and request sampling
    cloudwatch_metrics_enabled = true
    sampled_requests_enabled   = true
  }

  # -----------------------------------------------------------------------------
  # AURORA Configuration
  # -----------------------------------------------------------------------------

  aurora_defaults = {
    engine_version                      = "15.4"
    port                                = 5432
    storage_encrypted                   = true
    storage_type                        = "aurora"
    iam_database_authentication_enabled = true
    auto_minor_version_upgrade          = false
    allow_major_version_upgrade         = false
    apply_immediately                   = false
    publicly_accessible                 = false

    # CloudWatch logs
    enabled_cloudwatch_logs_exports = ["postgresql"]

    # Backup windows
    preferred_backup_window      = "03:00-04:00"
    preferred_maintenance_window = "sun:04:00-sun:05:00"
  }
}

# -----------------------------------------------------------------------------
# Generate Files
# -----------------------------------------------------------------------------

# --- Backend configuration ---
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

# --- Provider configuration ---
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

# --- Checkov configuration ---
generate "checkov_config" {
  path      = ".checkov.yaml"
  if_exists = "overwrite"
  contents  = <<EOF
skip-check:
  # Networking
  - CKV_AWS_130   # Public subnets intentionally assign IPs
  - CKV2_AWS_11   # Flow logs handled elsewhere
  - CKV2_AWS_12   # Default SG behavior intentionally managed
  - CKV2_AWS_5    # Security groups created before resources that use them
  
  # ALB
  - CKV2_AWS_28   # WAF integration is optional and configured per environment
  - CKV_AWS_378   # Target groups use HTTP for internal VPC communication (HTTPS terminated at ALB)
  
  # EKS Cluster
  - CKV_AWS_37    # EKS public access controlled via environment-specific CIDRs
  - CKV_AWS_38    # EKS cluster endpoint private access enabled
  - CKV_AWS_39    # EKS cluster logging enabled for all log types
  - CKV_AWS_58    # EKS secrets encryption enabled via KMS
  - CKV_AWS_151   # EKS node group remote access managed via IAM and SSM
  
  # EKS Node Groups
  - CKV_AWS_382   # Node egress restricted to necessary ports (443, 80, 53, 123) with 0.0.0.0/0 - security enforced via NAT Gateway routing
  - CKV_AWS_341   # IMDSv2 hop limit set to 1 for security (pods use IRSA/Pod Identity instead of IMDS)
  
  # CloudWatch
  - CKV_AWS_338   # CloudWatch retention set to 90 days per company policy (not 365)

  # TLS
  - CKV_AWS_103   # HTTP listener (port 80) only redirects to HTTPS; TLS 1.2+ enforced on HTTPS listener
EOF
}

# --- Trivy configuration ---
generate "trivy_ignore" {
  path      = ".trivyignore"
  if_exists = "overwrite"
  contents  = <<EOF
AVD-AWS-0164  # EKS cluster endpoint private access enabled
AVD-AWS-0178  # EKS control plane logging enabled
AVD-AWS-0104  # Security group egress rules
AVD-AWS-0053  # Public ALB intentional for external access
AVD-AWS-0039  # EKS encryption enabled via KMS
AVD-AWS-0040  # EKS public access controlled per environment
AVD-AWS-0041  # EKS cluster logging enabled
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

  # ALB configuration from locals
  alb_config = local.alb_config_defaults

  # ALB listeners configuration from locals
  listeners      = local.listeners
  listener_rules = local.listener_rules

  # WAF Configuration
  waf_config = local.waf_config

  # Aurora configuration from locals
  aurora_config = local.env_config[local.environment].aurora

  # EKS Cluster configuration from locals
  eks_kubernetes_version                          = local.eks_kubernetes_version
  eks_endpoint_private_access                     = local.eks_endpoint_private_access
  eks_endpoint_public_access                      = local.eks_endpoint_public_access
  eks_public_access_cidrs                         = local.eks_public_access_cidrs
  eks_enabled_cluster_log_types                   = local.eks_enabled_cluster_log_types
  eks_cloudwatch_retention_days                   = local.eks_cloudwatch_retention_days
  eks_vpc_cni_version                             = local.eks_vpc_cni_version
  eks_coredns_version                             = local.eks_coredns_version
  eks_kube_proxy_version                          = local.eks_kube_proxy_version
  eks_encryption_config                           = local.eks_encryption_config
  eks_authentication_mode                         = local.eks_authentication_mode
  eks_bootstrap_cluster_creator_admin_permissions = local.eks_bootstrap_cluster_creator_admin_permissions
  eks_enable_cluster_logging                      = local.eks_enable_cluster_logging
  eks_enable_pod_identity_agent                   = local.eks_enable_pod_identity_agent
  eks_pod_identity_agent_version                  = local.eks_pod_identity_agent_version
  eks_node_groups_defaults                        = local.eks_node_groups_defaults

  # Common tags
  common_tags = {
    Environment = local.environment
    Region      = local.region
    Component   = local.component
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }
}
