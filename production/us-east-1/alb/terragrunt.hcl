# -----------------------------------------------------------------------------
# ALB - ENVIRONMENT CONFIGURATION
# -----------------------------------------------------------------------------
#
# Author: Alex
# Environment: [SET PER ENVIRONMENT]
# Module: terraform-aws-alb
#
# Description:
#   Environment-specific configuration for Application Load Balancer deployment.
#   This file defines the ALB configuration for this environment by combining
#   templates from _env_helpers/alb.hcl with environment-specific overrides.
#
# Structure:
#   - Inherits common configuration from root terragrunt.hcl
#   - Loads ALB helper templates from _env_helpers/alb.hcl
#   - Defines environment-specific ALB configuration
#   - Configures dependencies on networking and security groups
#
# Dependencies:
#   - VPC and subnets (from networking stack)
#   - Security groups (from security-groups stack)
#   - Optional: ACM certificate (for HTTPS)
#   - Optional: WAF web ACL (for application protection)
#
# Usage:
#   terragrunt plan
#   terragrunt apply
#   terragrunt destroy
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# COMMON CONFIGURATION
# -----------------------------------------------------------------------------

include "root" {
  path = find_in_parent_folders("root.hcl")
}

# -----------------------------------------------------------------------------
# HELPERS AND TEMPLATES
# -----------------------------------------------------------------------------

locals {
  # Load common configuration from root
  root_config = read_terragrunt_config(find_in_parent_folders("root.hcl"))
  environment = local.root_config.locals.environment
  region      = local.root_config.locals.region
  account_id  = local.root_config.locals.account_id

  # Load ALB helper templates
  alb_helpers = read_terragrunt_config(find_in_parent_folders("_env_helpers/alb.hcl"))

  # ---------------------------------------------------------------------------
  # ENVIRONMENT-SPECIFIC CONFIGURATION
  # ---------------------------------------------------------------------------

  # VPC configuration (from dependency)
  # vpc_id will be set from dependency outputs

  # Subnet selection - adjust based on your VPC setup
  # subnet_ids will be set from dependency outputs (typically public subnets for internet-facing ALB)

  # Security group configuration
  # security_group_ids will be set from dependency outputs

  # Certificate ARN for HTTPS (set to null for HTTP-only ALB)
  # Example: "arn:aws:acm:us-east-1:123456789012:certificate/abc123..."
  certificate_arn = null

  # WAF Web ACL ARN for application protection (optional)
  # Example: "arn:aws:wafv2:us-east-1:123456789012:regional/webacl/my-waf/abc123..."
  waf_web_acl_arn = null

  # Access logs S3 bucket (optional, recommended for production)
  # Example: "my-alb-access-logs-bucket"
  access_logs_bucket = null

  # ---------------------------------------------------------------------------
  # ALB CONFIGURATION
  # ---------------------------------------------------------------------------

  # Base ALB configuration - choose a template or build custom
  base_alb_config = local.alb_helpers.locals.alb_templates.public_web_alb

  # Environment-specific overrides and additions
  alb_config = merge(
    local.base_alb_config,
    {
      # ALB name suffix (will be prefixed with environment automatically)
      name_suffix = "app-alb"

      # Network configuration (from dependencies)
      subnet_ids         = dependency.networking.outputs.public_subnet_ids
      security_group_ids = [dependency.security_groups.outputs.alb_security_group_id]

      # Certificate configuration
      certificate_arn = local.certificate_arn

      # Optional features
      waf_web_acl_arn    = local.waf_web_acl_arn
      access_logs_bucket = local.access_logs_bucket

      # Override access logs enabled based on environment
      access_logs_enabled = local.environment == "production" ? true : false

      # Override deletion protection based on environment
      enable_deletion_protection = local.environment == "production" ? true : false

      # Target groups configuration
      # Customize based on your application needs
      target_groups = {
        web = {
          port                 = 80
          protocol             = "HTTP"
          target_type          = "instance"
          deregistration_delay = 300
          health_check = {
            enabled             = true
            healthy_threshold   = 3
            interval            = 30
            matcher             = "200"
            path                = "/health"
            port                = "traffic-port"
            protocol            = "HTTP"
            timeout             = 5
            unhealthy_threshold = 3
          }
          stickiness = null
        }
      }
    }
  )

  # ---------------------------------------------------------------------------
  # TAGS
  # ---------------------------------------------------------------------------

  tags = merge(
    local.root_config.locals.common_tags,
    {
      Name        = "${local.environment}-${local.alb_config.name_suffix}"
      Component   = "load-balancer"
      Application = "web-application"
      ManagedBy   = "terragrunt"
    }
  )
}

# -----------------------------------------------------------------------------
# MODULE SOURCE
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules//alb"
}

# -----------------------------------------------------------------------------
# DEPENDENCIES
# -----------------------------------------------------------------------------

dependency "networking" {
  config_path = "../networking"

  mock_outputs = {
    vpc_id             = "vpc-mockid1234"
    public_subnet_ids  = ["subnet-mock1234", "subnet-mock5678", "subnet-mock9012"]
    private_subnet_ids = ["subnet-mock3456", "subnet-mock7890", "subnet-mock1234"]
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

dependency "security_groups" {
  config_path = "../security-groups"

  mock_outputs = {
    alb_security_group_id = "sg-mockid1234"
  }

  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}

# -----------------------------------------------------------------------------
# MODULE INPUTS
# -----------------------------------------------------------------------------

inputs = {
  environment = local.environment
  region      = local.region
  vpc_id      = dependency.networking.outputs.vpc_id
  alb_config  = local.alb_config
  tags        = local.tags
}

# -----------------------------------------------------------------------------
# TERRAFORM CONFIGURATION
# -----------------------------------------------------------------------------

# Generate provider configuration
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<EOF
provider "aws" {
  region = "${local.region}"

  default_tags {
    tags = {
      Environment = "${local.environment}"
      ManagedBy   = "terragrunt"
      Repository  = "infrastructure"
    }
  }
}
EOF
}

# -----------------------------------------------------------------------------
# STATE MANAGEMENT
# -----------------------------------------------------------------------------

# Remote state configuration inherited from root.hcl
# State will be stored at: s3://[bucket]/[environment]/alb/terraform.tfstate
