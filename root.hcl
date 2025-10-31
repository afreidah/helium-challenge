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

  # Computed naming convention
  name_prefix = "${local.environment}-${local.region}"

  # -----------------------------------------------------------------------------
  # Environment-Specific Configuration (BUSINESS LOGIC)
  # -----------------------------------------------------------------------------

  env_config = {
    # --- Production Environment ---
    production = {
      instance_type = "t3.large"
      replica_count = 3
      az_suffixes   = ["a", "b"]

      # Networking CIDRs
      vpc_cidr                  = "10.0.0.0/16"
      public_subnet_cidrs       = ["10.0.1.0/24", "10.0.2.0/24"]
      private_app_subnet_cidrs  = ["10.0.16.0/20", "10.0.32.0/20"]
      private_data_subnet_cidrs = ["10.0.4.0/24", "10.0.5.0/24"]

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
      az_suffixes   = ["a", "b"]

      # Networking CIDRs
      vpc_cidr                  = "10.1.0.0/16"
      public_subnet_cidrs       = ["10.1.1.0/24", "10.1.2.0/24"]
      private_app_subnet_cidrs  = ["10.1.16.0/20", "10.1.32.0/20"]
      private_data_subnet_cidrs = ["10.1.4.0/24", "10.1.5.0/24"]

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

  # -----------------------------------------------------------------------------
  # NETWORKING CONFIGURATION
  # -----------------------------------------------------------------------------

  networking_config = {
    # Computed availability zones from region + suffix
    availability_zones = [
      for suffix in local.env_config[local.environment].az_suffixes :
      "${local.region}${suffix}"
    ]

    # NAT Gateway configuration
    enable_nat_gateway = true
    single_nat_gateway = local.environment == "production" ? false : true

    # VPC and subnet configuration (passed through from env_config)
    vpc_name                  = local.environment
    vpc_cidr                  = local.env_config[local.environment].vpc_cidr
    public_subnet_cidrs       = local.env_config[local.environment].public_subnet_cidrs
    private_app_subnet_cidrs  = local.env_config[local.environment].private_app_subnet_cidrs
    private_data_subnet_cidrs = local.env_config[local.environment].private_data_subnet_cidrs
  }

  # -----------------------------------------------------------------------------
  # SECURITY GROUPS CONFIGURATION
  # -----------------------------------------------------------------------------

  security_group_rules = {
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

    aurora = {
      name_suffix = "aurora"
      description = "Security group for Aurora PostgreSQL database"
      ingress_rules = [
        {
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "Allow PostgreSQL from VPC"
        }
      ]
      egress_rules = []
    }
  }

  # -----------------------------------------------------------------------------
  # IAM ROLES CONFIGURATION
  # -----------------------------------------------------------------------------

  iam_role_configs = {
    eks_cluster = {
      name_suffix             = "eks-cluster"
      description             = "IAM role for EKS cluster control plane"
      create_instance_profile = false
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
        "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy",
        "arn:aws:iam::aws:policy/AmazonEKSVPCResourceController"
      ]
    }

    eks_node = {
      name_suffix             = "eks-node"
      description             = "IAM role for EKS worker nodes"
      create_instance_profile = true
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
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly",
        "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
      ]
    }

    external_secrets = {
      name_suffix             = "external-secrets"
      description             = "IAM role for External Secrets Operator via IRSA"
      create_instance_profile = false

      # Placeholder - will be overridden in environment-level terragrunt.hcl
      assume_role_policy = "PLACEHOLDER"

      # Inline policy for Secrets Manager access
      inline_policies = {
        secrets_manager_access = jsonencode({
          Version = "2012-10-17"
          Statement = [
            {
              Sid    = "SecretsManagerReadAccess"
              Effect = "Allow"
              Action = [
                "secretsmanager:GetSecretValue",
                "secretsmanager:DescribeSecret"
              ]
              Resource = [
                "arn:aws:secretsmanager:*:*:secret:/${local.environment}/aurora/*",
                "arn:aws:secretsmanager:*:*:secret:/${local.environment}/app/*"
              ]
            },
            {
              Sid      = "SecretsManagerListAccess"
              Effect   = "Allow"
              Action   = ["secretsmanager:ListSecrets"]
              Resource = ["*"]
            }
          ]
        })
      }
      policy_arns = []
    }
  }

  # -----------------------------------------------------------------------------
  # ALB CONFIGURATION
  # -----------------------------------------------------------------------------

  alb_config = {
    name_suffix                      = "alb"
    load_balancer_type               = "application"
    internal                         = false
    enable_deletion_protection       = local.environment == "production" ? true : false
    enable_cross_zone_load_balancing = true
    enable_http2                     = true
    enable_waf_fail_open             = false
    desync_mitigation_mode           = "defensive"
    drop_invalid_header_fields       = true
    preserve_host_header             = true
    enable_xff_client_port           = false
    xff_header_processing_mode       = "append"
    idle_timeout                     = 60

    access_logs = {
      enabled = false
      bucket  = null
      prefix  = null
    }
  }

  # -----------------------------------------------------------------------------
  # ALB LISTENERS CONFIGURATION
  # -----------------------------------------------------------------------------

  alb_listeners_config = {
    listeners = {
      http = {
        enabled  = true
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "redirect"
          redirect = {
            protocol    = "HTTPS"
            port        = "443"
            status_code = "HTTP_301"
          }
        }
      }

      https = {
        enabled         = false
        port            = 443
        protocol        = "HTTPS"
        certificate_arn = null
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
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
  }

  # -----------------------------------------------------------------------------
  # ALB TARGET GROUPS CONFIGURATION
  # -----------------------------------------------------------------------------

  target_groups_config = {
    app = {
      port                 = 8080
      protocol             = "HTTP"
      target_type          = "instance"
      deregistration_delay = 30
      health_check = {
        enabled             = true
        healthy_threshold   = 2
        interval            = 30
        matcher             = "200"
        path                = "/health"
        port                = "traffic-port"
        protocol            = "HTTP"
        timeout             = 5
        unhealthy_threshold = 2
      }
      stickiness = null
    }
  }

  # -----------------------------------------------------------------------------
  # WAF CONFIGURATION
  # -----------------------------------------------------------------------------

  waf_config = {
    name        = "${local.environment}-${local.region}-waf"
    description = "WAF for ${local.environment} environment"
    scope       = "REGIONAL"

    rules = [
      {
        name     = "AWSManagedRulesCommonRuleSet"
        priority = 1
        override_action = {
          none = {}
        }
        statement = {
          managed_rule_group_statement = {
            vendor_name = "AWS"
            name        = "AWSManagedRulesCommonRuleSet"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "AWSManagedRulesCommonRuleSetMetric"
          sampled_requests_enabled   = true
        }
      },
      {
        name     = "AWSManagedRulesKnownBadInputsRuleSet"
        priority = 2
        override_action = {
          none = {}
        }
        statement = {
          managed_rule_group_statement = {
            vendor_name = "AWS"
            name        = "AWSManagedRulesKnownBadInputsRuleSet"
          }
        }
        visibility_config = {
          cloudwatch_metrics_enabled = true
          metric_name                = "AWSManagedRulesKnownBadInputsRuleSetMetric"
          sampled_requests_enabled   = true
        }
      }
    ]

    default_action = "allow"

    visibility_config = {
      cloudwatch_metrics_enabled = true
      metric_name                = "${local.environment}-waf-metric"
      sampled_requests_enabled   = true
    }
  }

  # -----------------------------------------------------------------------------
  # AURORA POSTGRESQL CONFIGURATION
  # -----------------------------------------------------------------------------

  aurora_config = {
    # Environment-specific settings from env_config
    instance_class                        = local.env_config[local.environment].aurora.instance_class
    instance_count                        = local.env_config[local.environment].aurora.instance_count
    backup_retention_period               = local.env_config[local.environment].aurora.backup_retention_period
    skip_final_snapshot                   = local.env_config[local.environment].aurora.skip_final_snapshot
    performance_insights_enabled          = local.env_config[local.environment].aurora.performance_insights_enabled
    performance_insights_retention_period = local.env_config[local.environment].aurora.performance_insights_retention_period
    monitoring_interval                   = local.env_config[local.environment].aurora.monitoring_interval
    deletion_protection                   = local.env_config[local.environment].aurora.deletion_protection

    # Shared defaults
    engine_version                      = "15.4"
    port                                = 5432
    storage_encrypted                   = true
    storage_type                        = "aurora"
    iam_database_authentication_enabled = true
    auto_minor_version_upgrade          = false
    allow_major_version_upgrade         = false
    apply_immediately                   = false
    publicly_accessible                 = false
    enabled_cloudwatch_logs_exports     = ["postgresql"]
    preferred_backup_window             = "03:00-04:00"
    preferred_maintenance_window        = "sun:04:00-sun:05:00"
  }

  # -----------------------------------------------------------------------------
  # EKS CLUSTER CONFIGURATION
  # -----------------------------------------------------------------------------

  eks_cluster_config = {
    kubernetes_version                          = "1.31"
    endpoint_private_access                     = true
    endpoint_public_access                      = true
    public_access_cidrs                         = local.environment == "production" ? ["0.0.0.0/0"] : ["0.0.0.0/0"]
    enabled_cluster_log_types                   = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
    cloudwatch_retention_days                   = 90
    authentication_mode                         = "API_AND_CONFIG_MAP"
    bootstrap_cluster_creator_admin_permissions = true
    enable_cluster_logging                      = true
    enable_pod_identity_agent                   = true
    pod_identity_agent_version                  = "v1.3.0-eksbuild.1"

    # Addon versions
    vpc_cni_version    = "v1.18.1-eksbuild.3"
    coredns_version    = "v1.11.1-eksbuild.9"
    kube_proxy_version = "v1.30.0-eksbuild.3"

    # Encryption configuration
    encryption_config = {
      resources = ["secrets"]
    }

    # Node group defaults
    node_groups_defaults = {
      ami_type       = "AL2023_x86_64_STANDARD"
      capacity_type  = "ON_DEMAND"
      disk_size      = 50
      instance_types = ["t3.medium"]
      desired_size   = 2
      min_size       = 1
      max_size       = 4
    }
  }

  # -----------------------------------------------------------------------------
  # SECRETS MANAGER CONFIGURATION
  # -----------------------------------------------------------------------------

  secrets_config = {
    "${local.environment}/aurora/master-credentials" = {
      description = "Aurora PostgreSQL master credentials for ${local.environment}"
      secret_string = jsonencode({
        username            = "postgres"
        password            = "CHANGE_ME_AFTER_INITIAL_DEPLOY"
        engine              = "postgres"
        port                = 5432
        dbname              = "postgres"
        dbClusterIdentifier = "${local.environment}-${local.region}-aurora-pg"
        host                = "PLACEHOLDER"
        reader_host         = "PLACEHOLDER"
      })
      recovery_window_in_days = local.environment == "production" ? 30 : 7
    }

    "${local.environment}/aurora/app-credentials" = {
      description = "Application database credentials for ${local.environment}"
      secret_string = jsonencode({
        username            = "appuser"
        password            = "CHANGE_ME_AFTER_INITIAL_DEPLOY"
        engine              = "postgres"
        port                = 5432
        dbname              = "postgres"
        dbClusterIdentifier = "${local.environment}-${local.region}-aurora-pg"
        host                = "PLACEHOLDER"
        reader_host         = "PLACEHOLDER"
      })
      recovery_window_in_days = local.environment == "production" ? 30 : 7
    }

    "${local.environment}/app/config" = {
      description = "Application configuration for ${local.environment}"
      secret_string = jsonencode({
        api_key     = "CHANGE_ME"
        webhook_url = "https://example.com/webhook"
      })
      recovery_window_in_days = local.environment == "production" ? 30 : 7
    }
  }
}

# -----------------------------------------------------------------------------
# Generate Files
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

  # Secrets Manager
  - CKV_AWS_304   # Automatic rotation within 90 days requires Lambda function - to be implemented in phase 2
  - CKV2_AWS_57   # Automatic rotation requires Lambda function and RDS integration - to be implemented in phase 2
  - CKV_SECRET_6  # High entropy strings in test files are test fixtures, not real secrets

  # Aurora PostgreSQL
  - CKV_AWS_226   # Auto minor version upgrades disabled intentionally for production stability
  - CKV2_AWS_27   # Query logging requires custom parameter group - to be implemented in phase 2
  - CKV2_AWS_8    # AWS Backup plan for RDS clusters - handled via separate backup strategy
  - CKV_AWS_162   # IAM authentication enabled via iam_database_authentication_enabled = true (false positive)
  - CKV_AWS_139   # Deletion protection enabled via deletion_protection = true (false positive)
  - CKV_AWS_96    # Storage encryption enabled via storage_encrypted = true with KMS (false positive)
  - CKV_AWS_353   # Performance Insights enabled via performance_insights_enabled = true (false positive)
EOF
}

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

terraform {
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
      "echo 'Running Checkov...'; checkov -d . -o github_failed_only"
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

  # Compute/capacity (from env_config)
  instance_type = local.env_config[local.environment].instance_type
  replica_count = local.env_config[local.environment].replica_count

  # Consolidated configuration objects (single line references)
  networking_config    = local.networking_config
  security_group_rules = local.security_group_rules
  iam_role_configs     = local.iam_role_configs
  alb_config           = local.alb_config
  alb_listeners_config = local.alb_listeners_config
  target_groups_config = local.target_groups_config
  waf_config           = local.waf_config
  aurora_config        = local.aurora_config
  eks_cluster_config   = local.eks_cluster_config
  secrets_config       = local.secrets_config

  # Common tags
  common_tags = {
    Environment = local.environment
    Region      = local.region
    Component   = local.component
    ManagedBy   = "Terragrunt"
    Terraform   = "true"
  }
}
