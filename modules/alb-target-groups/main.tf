# -----------------------------------------------------------------------------
# ALB TARGET GROUPS MODULE
# -----------------------------------------------------------------------------
#
# This module creates ALB target groups for routing traffic to backend
# application instances or IP addresses. Target groups are independent of
# the ALB and can be attached to listeners separately.
#
# Components Created:
#   - Target Groups: Backend pools for routing traffic
#   - Health Checks: Independent health check configuration per target group
#   - Session Stickiness: Optional cookie-based session affinity
#
# Features:
#   - Multiple target groups with independent configuration
#   - Configurable health checks per target group
#   - Support for instance and IP target types
#   - Session stickiness with configurable duration
#   - Deregistration delay for graceful shutdown
#   - Automatic name prefixing with environment
#   - 32-character name limit handling with automatic truncation
#
# Target Types:
#   - instance: Route to EC2 instance IDs (for EKS nodes)
#   - ip: Route to IP addresses (for EKS pods with AWS VPC CNI)
#   - lambda: Route to Lambda functions
#   - alb: Route to another ALB
#
# Health Check Model:
#   - Independent health checks per target group
#   - Configurable protocol, path, and thresholds
#   - Health check results determine target availability
#
# Dependency Chain:
#   1. general-networking (VPC)
#   2. alb (load balancer created)
#   3. alb-target-groups (this module - creates target groups)
#   4. eks-node-group (nodes to register)
#   5. alb-target-group-attachments (register targets)
#   6. alb-listeners (create listeners that route to these groups)
#
# IMPORTANT:
#   - Target group names automatically truncated to 32 characters
#   - Target registration handled by separate alb-target-group-attachments module
#   - Health checks run continuously regardless of listener configuration
#   - Deregistration delay allows in-flight requests to complete
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# TARGET GROUPS
# -----------------------------------------------------------------------------
# Backend pools for routing traffic to application instances or IPs
# Each target group has independent configuration and health checks
# Names are automatically prefixed and truncated to 32 character limit

resource "aws_lb_target_group" "this" {
  for_each             = var.target_groups
  name                 = trimsuffix(substr("${var.environment}-${each.key}-tg", 0, 32), "-")
  port                 = each.value.port
  protocol             = each.value.protocol
  vpc_id               = var.vpc_id
  target_type          = each.value.target_type
  deregistration_delay = each.value.deregistration_delay

  # -------------------------------------------------------------------------
  # HEALTH CHECK CONFIGURATION
  # -------------------------------------------------------------------------
  # Determines target availability for traffic routing
  health_check {
    enabled             = each.value.health_check.enabled
    healthy_threshold   = each.value.health_check.healthy_threshold
    interval            = each.value.health_check.interval
    matcher             = each.value.health_check.matcher
    path                = each.value.health_check.path
    port                = each.value.health_check.port
    protocol            = each.value.health_check.protocol
    timeout             = each.value.health_check.timeout
    unhealthy_threshold = each.value.health_check.unhealthy_threshold
  }

  # -------------------------------------------------------------------------
  # SESSION STICKINESS
  # -------------------------------------------------------------------------
  # Optional cookie-based session affinity to same target
  dynamic "stickiness" {
    for_each = each.value.stickiness != null ? [each.value.stickiness] : []
    content {
      enabled         = stickiness.value.enabled
      type            = stickiness.value.type
      cookie_duration = stickiness.value.cookie_duration
    }
  }

  tags = merge(
    var.common_tags,
    {
      Name = "${var.environment}-${each.key}-tg"
    }
  )

  lifecycle {
    create_before_destroy = true
  }
}
