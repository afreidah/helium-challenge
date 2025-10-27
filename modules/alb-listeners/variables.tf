# -----------------------------------------------------------------------------
# ALB LISTENERS VARIABLES
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

variable "alb_arn" {
  description = "ARN of the Application Load Balancer"
  type        = string
}

variable "listeners" {
  description = "Listener configurations for HTTP and HTTPS"
  type = object({
    http = object({
      enabled  = bool
      port     = number
      protocol = string
      default_action = object({
        type             = string
        target_group_arn = optional(string)
        redirect         = optional(map(string))
        fixed_response   = optional(map(string))
      })
    })
    https = object({
      enabled         = bool
      port            = number
      protocol        = string
      ssl_policy      = string
      certificate_arn = optional(string)
      default_action = object({
        type             = string
        target_group_arn = optional(string)
        redirect         = optional(map(string))
        fixed_response   = optional(map(string))
      })
    })
  })
}

variable "listener_rules" {
  description = "Map of listener rules for path-based and host-based routing"
  type = map(object({
    listener_protocol = string
    priority          = number
    conditions = list(object({
      type             = string
      values           = list(string)
      http_header_name = optional(string)
    }))
    action = object({
      type             = string
      target_group_arn = optional(string)
      redirect         = optional(map(string))
      fixed_response   = optional(map(string))
    })
  }))
  default = {}
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
