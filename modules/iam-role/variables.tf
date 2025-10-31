# -----------------------------------------------------------------------------
# IAM ROLE MODULE - INPUT VARIABLES
# -----------------------------------------------------------------------------
#
# This file defines all configurable parameters for the IAM role module,
# including role identity, trust policy, permission attachments, and
# instance profile options.
#
# Variable Categories:
#   - Core Configuration: Environment, region, and role configuration object
#   - Role Config Object: Contains name, trust policy, permissions, and options
#   - Tagging: Resource tags for organization
#
# Role Configuration Structure:
#   - name_suffix: Appended to environment for full role name
#   - description: Human-readable role description
#   - assume_role_policy: JSON trust policy document
#   - policy_arns: List of AWS managed policy ARNs to attach
#   - create_instance_profile: Whether to create EC2 instance profile
#
# Trust Policy Examples:
#   - EC2: { Principal = { Service = "ec2.amazonaws.com" } }
#   - Lambda: { Principal = { Service = "lambda.amazonaws.com" } }
#   - ECS Tasks: { Principal = { Service = "ecs-tasks.amazonaws.com" } }
#   - Cross-Account: { Principal = { AWS = "arn:aws:iam::123456789012:root" } }
#   - EKS: { Principal = { Service = "eks.amazonaws.com" } }
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# CORE CONFIGURATION
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string

  validation {
    condition     = can(regex("^(production|staging|development|prod|stage|dev)$", var.environment))
    error_message = "Environment must be one of: production, staging, development, prod, stage, dev."
  }
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "role_config" {
  description = "IAM role configuration from root.hcl containing name, trust policy, and managed policies"
  type = object({
    name_suffix             = string
    description             = string
    assume_role_policy      = string
    policy_arns             = list(string)
    create_instance_profile = bool
    inline_policies         = optional(map(string), {})
  })

  validation {
    condition     = length(var.role_config.name_suffix) > 0 && length(var.role_config.name_suffix) <= 50
    error_message = "Role name_suffix must be between 1 and 50 characters."
  }

  validation {
    condition     = length(var.role_config.description) > 0 && length(var.role_config.description) <= 1000
    error_message = "Role description must be between 1 and 1000 characters."
  }
}

# -----------------------------------------------------------------------------
# TAGGING
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to IAM role"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be <= 128 characters and values must be <= 256 characters."
  }
}
