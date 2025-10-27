# -----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER MODULE
# -----------------------------------------------------------------------------
#
# This module creates an Application Load Balancer (ALB) resource without
# listeners or target groups. Listeners and target groups are managed by
# separate modules with proper dependency chains.
#
# Components Created:
#   - Application Load Balancer: Layer 7 load balancer for HTTP/HTTPS traffic
#
# Features:
#   - Centralized ALB configuration in root.hcl
#   - Automatic name prefixing with environment
#   - Cross-zone load balancing for high availability
#   - HTTP/2 support for improved performance
#   - Invalid header field filtering for security
#   - Optional access logging to S3
#   - Desync mitigation for security
#   - XFF header processing configuration
#
# Security Model:
#   - Invalid header fields dropped by default
#   - Security groups control inbound/outbound traffic (from dependency)
#   - Optional WAF integration for application layer protection
#   - Desync mitigation enabled by default
#
# Dependency Chain:
#   1. general-networking (VPC, subnets)
#   2. security-groups-alb (security group for ALB)
#   3. alb (this module - creates load balancer)
#   4. alb-target-groups (creates target groups)
#   5. alb-listeners (creates listeners, attaches to ALB and target groups)
#
# IMPORTANT:
#   - ALB name automatically prefixed with environment for uniqueness
#   - Deletion protection disabled by default for non-production flexibility
#   - Listeners and target groups managed by separate modules
#   - Subnets must be public for internet-facing ALBs
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER
# -----------------------------------------------------------------------------
# Load balancer for distributing HTTP/HTTPS traffic
# Can be internet-facing or internal based on alb_config.internal setting
# Name is automatically prefixed with environment

resource "aws_lb" "this" {
  #tfsec:ignore:aws-elb-alb-not-public Intentional: Public ALB by design
  name               = "${var.environment}-${var.alb_config.name_suffix}"
  internal           = var.alb_config.internal
  load_balancer_type = var.alb_config.load_balancer_type
  security_groups    = var.alb_config.security_group_ids
  subnets            = var.alb_config.subnet_ids

  enable_deletion_protection       = var.alb_config.enable_deletion_protection
  enable_http2                     = var.alb_config.enable_http2
  enable_cross_zone_load_balancing = var.alb_config.enable_cross_zone_load_balancing
  idle_timeout                     = var.alb_config.idle_timeout
  drop_invalid_header_fields       = var.alb_config.drop_invalid_header_fields
  desync_mitigation_mode           = var.alb_config.desync_mitigation_mode
  enable_waf_fail_open             = var.alb_config.enable_waf_fail_open
  preserve_host_header             = var.alb_config.preserve_host_header
  enable_xff_client_port           = var.alb_config.enable_xff_client_port
  xff_header_processing_mode       = var.alb_config.xff_header_processing_mode

  # -------------------------------------------------------------------------
  # ACCESS LOGGING
  # -------------------------------------------------------------------------
  # Optional S3 access logs for request-level visibility
  dynamic "access_logs" {
    for_each = var.alb_config.access_logs.enabled ? [1] : []
    content {
      bucket  = var.alb_config.access_logs.bucket
      prefix  = var.alb_config.access_logs.prefix
      enabled = true
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${var.alb_config.name_suffix}"
    }
  )
}
