# -----------------------------------------------------------------------------
# ALB TARGET GROUPS VARIABLES
# -----------------------------------------------------------------------------

variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string
}

variable "component" {
  description = "Component name for resource identification"
  type        = string
}

variable "vpc_id" {
  description = "VPC ID where target groups will be created"
  type        = string
}

variable "target_groups" {
  description = "Map of target group configurations"
  type = map(object({
    port                 = number
    protocol             = string
    target_type          = string
    deregistration_delay = number
    health_check = object({
      enabled             = bool
      healthy_threshold   = number
      interval            = number
      matcher             = string
      path                = string
      port                = string
      protocol            = string
      timeout             = number
      unhealthy_threshold = number
    })
    stickiness = optional(object({
      enabled         = bool
      type            = string
      cookie_duration = number
    }))
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
