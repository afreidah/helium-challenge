# -----------------------------------------------------------------------------
# ALB MODULE - INPUT VARIABLES
# -----------------------------------------------------------------------------
#
# This file defines all configurable parameters for the Application Load
# Balancer module, including ALB configuration, target group settings,
# listener options, and security features.
#
# Variable Categories:
#   - Core Configuration: Environment, region, and ALB configuration object
#   - ALB Config Object: Contains all ALB settings including networking, security,
#     target groups, and listener configuration
#   - Tagging: Resource tags for organization
#
# ALB Configuration Structure:
#   - name_suffix: Appended to environment for full ALB name
#   - internal: Whether ALB is internet-facing or internal
#   - subnet_ids: List of subnet IDs (from networking dependency)
#   - security_group_ids: List of security group IDs (from SG dependency)
#   - certificate_arn: Optional SSL/TLS certificate for HTTPS
#   - target_groups: Map of target group configurations with health checks
#   - Performance settings: HTTP/2, cross-zone LB, timeouts
#   - Security settings: Header filtering, deletion protection
#   - Logging: Access logs configuration
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

variable "vpc_id" {
  description = "VPC ID where ALB will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id))
    error_message = "VPC ID must be a valid format (vpc-xxxxxxxx)."
  }
}

variable "alb_config" {
  description = "ALB configuration from root.hcl containing all ALB settings"
  type = object({
    name_suffix                      = string
    internal                         = bool
    subnet_ids                       = list(string)
    security_group_ids               = list(string)
    certificate_arn                  = optional(string)
    waf_web_acl_arn                  = optional(string)
    enable_http2                     = optional(bool, true)
    enable_cross_zone_load_balancing = optional(bool, true)
    idle_timeout                     = optional(number, 60)
    enable_deletion_protection       = optional(bool, false)
    drop_invalid_header_fields       = optional(bool, true)
    access_logs_enabled              = optional(bool, false)
    access_logs_bucket               = optional(string)
    target_groups = map(object({
      port                 = number
      protocol             = string
      target_type          = string
      deregistration_delay = optional(number, 300)
      health_check = object({
        enabled             = optional(bool, true)
        healthy_threshold   = optional(number, 3)
        interval            = optional(number, 30)
        matcher             = optional(string, "200")
        path                = optional(string, "/")
        port                = optional(string, "traffic-port")
        protocol            = optional(string, "HTTP")
        timeout             = optional(number, 5)
        unhealthy_threshold = optional(number, 3)
      })
      stickiness = optional(object({
        enabled         = optional(bool, false)
        type            = optional(string, "lb_cookie")
        cookie_duration = optional(number, 86400)
      }))
    }))
  })

  validation {
    condition     = length(var.alb_config.name_suffix) > 0 && length(var.alb_config.name_suffix) <= 50
    error_message = "ALB name_suffix must be between 1 and 50 characters."
  }

  validation {
    condition     = length(var.alb_config.subnet_ids) >= 2
    error_message = "ALB requires at least 2 subnets for high availability."
  }
}

# -----------------------------------------------------------------------------
# TAGGING
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to resources"
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
