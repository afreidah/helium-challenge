# -----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER VARIABLES
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

variable "alb_config" {
  description = "ALB configuration object from root.hcl"
  type = object({
    name_suffix                      = string
    load_balancer_type               = string
    internal                         = bool
    enable_deletion_protection       = bool
    enable_cross_zone_load_balancing = bool
    enable_http2                     = bool
    enable_waf_fail_open             = bool
    desync_mitigation_mode           = string
    drop_invalid_header_fields       = bool
    preserve_host_header             = bool
    enable_xff_client_port           = bool
    xff_header_processing_mode       = string
    idle_timeout                     = number
    subnet_ids                       = list(string)
    security_group_ids               = list(string)
    access_logs = object({
      enabled = bool
      bucket  = optional(string)
      prefix  = optional(string)
    })
  })
}

variable "common_tags" {
  description = "Common tags to apply to all resources"
  type        = map(string)
  default     = {}
}
