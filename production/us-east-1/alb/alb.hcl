# -----------------------------------------------------------------------------
# ALB CONFIGURATION HELPERS
# -----------------------------------------------------------------------------
#
# Author: Alex
# Purpose: Centralized ALB configuration templates and helper functions
#
# Description:
#   This file provides reusable ALB configuration patterns and helper functions
#   for consistent ALB deployments across environments. It contains common
#   target group configurations, health check patterns, and ALB templates that
#   can be customized per environment.
#
# Usage:
#   In environment-level terragrunt.hcl:
#     locals {
#       alb_helpers = read_terragrunt_config(find_in_parent_folders("_env_helpers/alb.hcl"))
#     }
#
#   Reference configurations:
#     alb_config = local.alb_helpers.locals.alb_templates.public_web_alb
#
# Configuration Categories:
#   - Health Check Patterns: Common health check configurations
#   - Target Group Templates: Reusable target group configurations
#   - ALB Templates: Complete ALB configuration patterns
#   - Helper Functions: Utility functions for ALB configuration
#
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # HEALTH CHECK PATTERNS
  # ---------------------------------------------------------------------------
  # Common health check configurations for different application types

  health_checks = {
    # Standard HTTP health check for web applications
    http_standard = {
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

    # Fast health check for APIs with quick response times
    http_fast = {
      enabled             = true
      healthy_threshold   = 2
      interval            = 15
      matcher             = "200"
      path                = "/health"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 3
      unhealthy_threshold = 2
    }

    # Lenient health check for slow-starting applications
    http_lenient = {
      enabled             = true
      healthy_threshold   = 2
      interval            = 30
      matcher             = "200,202"
      path                = "/health"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 10
      unhealthy_threshold = 5
    }

    # Root path health check (for applications without dedicated health endpoint)
    http_root = {
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      matcher             = "200"
      path                = "/"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 3
    }

    # API health check with specific endpoint
    api_standard = {
      enabled             = true
      healthy_threshold   = 3
      interval            = 30
      matcher             = "200"
      path                = "/api/health"
      port                = "traffic-port"
      protocol            = "HTTP"
      timeout             = 5
      unhealthy_threshold = 3
    }
  }

  # ---------------------------------------------------------------------------
  # TARGET GROUP TEMPLATES
  # ---------------------------------------------------------------------------
  # Reusable target group configurations for common patterns

  target_group_templates = {
    # Standard web application target group (EC2 instances)
    web_instance = {
      port                 = 80
      protocol             = "HTTP"
      target_type          = "instance"
      deregistration_delay = 300
      health_check         = local.health_checks.http_standard
      stickiness           = null
    }

    # API target group with IP targets (for ECS/Fargate)
    api_ip = {
      port                 = 8080
      protocol             = "HTTP"
      target_type          = "ip"
      deregistration_delay = 30
      health_check         = local.health_checks.api_standard
      stickiness           = null
    }

    # Application with session stickiness enabled
    web_sticky = {
      port                 = 80
      protocol             = "HTTP"
      target_type          = "instance"
      deregistration_delay = 300
      health_check         = local.health_checks.http_standard
      stickiness = {
        enabled         = true
        type            = "lb_cookie"
        cookie_duration = 86400 # 24 hours
      }
    }

    # Backend API on custom port
    backend_api = {
      port                 = 8080
      protocol             = "HTTP"
      target_type          = "ip"
      deregistration_delay = 30
      health_check         = local.health_checks.http_fast
      stickiness           = null
    }

    # Admin interface with lenient health checks
    admin_panel = {
      port                 = 3000
      protocol             = "HTTP"
      target_type          = "instance"
      deregistration_delay = 60
      health_check         = local.health_checks.http_lenient
      stickiness           = null
    }
  }

  # ---------------------------------------------------------------------------
  # ALB TEMPLATES
  # ---------------------------------------------------------------------------
  # Complete ALB configurations for common deployment patterns

  alb_templates = {
    # Public-facing web application ALB with HTTPS
    public_web_alb = {
      internal                         = false
      enable_http2                     = true
      enable_cross_zone_load_balancing = true
      idle_timeout                     = 60
      enable_deletion_protection       = false
      drop_invalid_header_fields       = true
      access_logs_enabled              = false
      access_logs_bucket               = null
      waf_web_acl_arn                  = null
      target_groups = {
        web = local.target_group_templates.web_instance
      }
    }

    # Internal API ALB (no HTTPS required)
    internal_api_alb = {
      internal                         = true
      enable_http2                     = true
      enable_cross_zone_load_balancing = true
      idle_timeout                     = 60
      enable_deletion_protection       = false
      drop_invalid_header_fields       = true
      access_logs_enabled              = false
      access_logs_bucket               = null
      waf_web_acl_arn                  = null
      target_groups = {
        api = local.target_group_templates.api_ip
      }
    }

    # Multi-tier application ALB (web + api)
    multi_tier_alb = {
      internal                         = false
      enable_http2                     = true
      enable_cross_zone_load_balancing = true
      idle_timeout                     = 60
      enable_deletion_protection       = false
      drop_invalid_header_fields       = true
      access_logs_enabled              = false
      access_logs_bucket               = null
      waf_web_acl_arn                  = null
      target_groups = {
        web = local.target_group_templates.web_instance
        api = local.target_group_templates.backend_api
      }
    }

    # Production ALB with security features enabled
    production_alb = {
      internal                         = false
      enable_http2                     = true
      enable_cross_zone_load_balancing = true
      idle_timeout                     = 60
      enable_deletion_protection       = true
      drop_invalid_header_fields       = true
      access_logs_enabled              = true
      access_logs_bucket               = null # Set per environment
      waf_web_acl_arn                  = null # Set per environment
      target_groups = {
        web = local.target_group_templates.web_instance
      }
    }
  }

  # ---------------------------------------------------------------------------
  # HELPER FUNCTIONS
  # ---------------------------------------------------------------------------

  # Helper function to merge ALB template with custom overrides
  # Usage: merge_alb_config("public_web_alb", { custom_key = "custom_value" })
  merge_alb_config = {
    base_template = "public_web_alb"
    overrides     = {}
    # Result would be: merge(local.alb_templates[base_template], overrides)
  }

  # Common port mappings
  ports = {
    http         = 80
    https        = 443
    app_server   = 8080
    admin        = 3000
    api          = 8081
    websocket    = 8082
    health_check = 9090
  }

  # Common matcher patterns
  matchers = {
    success         = "200"
    success_created = "200,201"
    success_all     = "200-299"
    redirect        = "301,302"
  }

  # Deregistration delay recommendations (seconds)
  deregistration_delays = {
    immediate = 0      # Not recommended except for testing
    fast      = 30     # For stateless APIs
    standard  = 300    # Default AWS value
    long      = 600    # For long-running requests
    extended  = 900    # Maximum safe value
  }

  # Session stickiness durations (seconds)
  stickiness_durations = {
    short   = 3600   # 1 hour
    medium  = 28800  # 8 hours
    long    = 86400  # 24 hours
    week    = 604800 # 7 days (maximum)
  }
}
