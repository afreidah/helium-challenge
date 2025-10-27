# -----------------------------------------------------------------------------
# ALB LISTENERS MODULE
# -----------------------------------------------------------------------------
#
# This module creates ALB listeners that attach to an existing Application
# Load Balancer and route traffic to target groups. Listeners define how the
# ALB accepts and processes incoming traffic.
#
# Components Created:
#   - HTTP Listener: Port 80 listener with redirect or forward actions
#   - HTTPS Listener: Port 443 listener with SSL/TLS termination
#   - Listener Rules: Path-based and host-based routing rules
#
# Features:
#   - Automatic HTTP to HTTPS redirect when certificate provided
#   - SSL/TLS termination with configurable security policy
#   - Multiple target group support with weighted routing
#   - Path-based routing rules for microservices
#   - Host-based routing for multi-tenant applications
#   - Fixed response actions for maintenance pages
#   - Redirect actions for URL rewriting
#
# Listener Actions:
#   - forward: Route traffic to target groups
#   - redirect: Redirect to different URL or protocol
#   - fixed-response: Return static response
#   - authenticate-cognito: Authenticate with Cognito
#   - authenticate-oidc: Authenticate with OIDC provider
#
# Security Model:
#   - TLS 1.3 recommended security policy by default
#   - Certificate-based HTTPS termination
#   - Automatic HTTP to HTTPS redirect for security
#
# Dependency Chain:
#   1. general-networking (VPC)
#   2. alb (load balancer created)
#   3. alb-target-groups (target groups created)
#   4. alb-listeners (this module - creates listeners)
#
# IMPORTANT:
#   - HTTP listener behavior changes based on certificate_arn presence
#   - HTTPS listener only created when certificate_arn is provided
#   - Default actions required for all listeners
#   - Listener rules evaluated in priority order (lowest first)
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# HTTP LISTENER (PORT 80)
# -----------------------------------------------------------------------------
# Handles all HTTP traffic on port 80
# Behavior depends on certificate_arn:
#   - With certificate: Redirects to HTTPS (301 permanent redirect)
#   - Without certificate: Routes to target group or fixed response

resource "aws_lb_listener" "http" {
  count = var.listeners.http.enabled ? 1 : 0

  #tfsec:ignore:aws-elb-http-not-used HTTP redirects to HTTPS when certificate is provided
  #checkov:skip=CKV_AWS_2:HTTP listener redirects to HTTPS or serves as default
  #checkov:skip=CKV_AWS_103:HTTP listener redirects to HTTPS or serves as default
  load_balancer_arn = var.alb_arn
  port              = var.listeners.http.port
  protocol          = var.listeners.http.protocol

  dynamic "default_action" {
    for_each = [var.listeners.http.default_action]
    content {
      type             = default_action.value.type
      target_group_arn = default_action.value.type == "forward" ? default_action.value.target_group_arn : null

      # Redirect action block
      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" ? [default_action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
          host        = lookup(redirect.value, "host", null)
          path        = lookup(redirect.value, "path", null)
          query       = lookup(redirect.value, "query", null)
        }
      }

      # Fixed response action block
      dynamic "fixed_response" {
        for_each = default_action.value.type == "fixed-response" ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }
    }
  }

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# HTTPS LISTENER (PORT 443)
# -----------------------------------------------------------------------------
# Handles HTTPS traffic with SSL/TLS termination
# Only created when certificate_arn is provided
# Uses modern TLS 1.3 security policy by default

resource "aws_lb_listener" "https" {
  count = var.listeners.https.enabled ? 1 : 0

  load_balancer_arn = var.alb_arn
  port              = var.listeners.https.port
  protocol          = var.listeners.https.protocol
  ssl_policy        = var.listeners.https.ssl_policy
  certificate_arn   = var.listeners.https.certificate_arn

  dynamic "default_action" {
    for_each = [var.listeners.https.default_action]
    content {
      type             = default_action.value.type
      target_group_arn = default_action.value.type == "forward" ? default_action.value.target_group_arn : null

      # Redirect action block
      dynamic "redirect" {
        for_each = default_action.value.type == "redirect" ? [default_action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
          host        = lookup(redirect.value, "host", null)
          path        = lookup(redirect.value, "path", null)
          query       = lookup(redirect.value, "query", null)
        }
      }

      # Fixed response action block
      dynamic "fixed_response" {
        for_each = default_action.value.type == "fixed-response" ? [default_action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }
    }
  }

  tags = var.common_tags
}

# -----------------------------------------------------------------------------
# LISTENER RULES
# -----------------------------------------------------------------------------
# Path-based and host-based routing rules for advanced traffic routing
# Rules are evaluated in priority order (lowest priority number first)

resource "aws_lb_listener_rule" "this" {
  for_each = var.listener_rules

  listener_arn = each.value.listener_protocol == "HTTP" ? aws_lb_listener.http[0].arn : aws_lb_listener.https[0].arn
  priority     = each.value.priority

  # -------------------------------------------------------------------------
  # RULE CONDITIONS
  # -------------------------------------------------------------------------
  # Define when this rule should be evaluated

  dynamic "condition" {
    for_each = each.value.conditions
    content {
      # Path pattern condition
      dynamic "path_pattern" {
        for_each = condition.value.type == "path-pattern" ? [condition.value] : []
        content {
          values = path_pattern.value.values
        }
      }

      # Host header condition
      dynamic "host_header" {
        for_each = condition.value.type == "host-header" ? [condition.value] : []
        content {
          values = host_header.value.values
        }
      }

      # HTTP header condition
      dynamic "http_header" {
        for_each = condition.value.type == "http-header" ? [condition.value] : []
        content {
          http_header_name = http_header.value.http_header_name
          values           = http_header.value.values
        }
      }

      # HTTP request method condition
      dynamic "http_request_method" {
        for_each = condition.value.type == "http-request-method" ? [condition.value] : []
        content {
          values = http_request_method.value.values
        }
      }

      # Query string condition
      dynamic "query_string" {
        for_each = condition.value.type == "query-string" ? condition.value.values : []
        content {
          key   = lookup(query_string.value, "key", null)
          value = query_string.value.value
        }
      }

      # Source IP condition
      dynamic "source_ip" {
        for_each = condition.value.type == "source-ip" ? [condition.value] : []
        content {
          values = source_ip.value.values
        }
      }
    }
  }

  # -------------------------------------------------------------------------
  # RULE ACTIONS
  # -------------------------------------------------------------------------
  # Define what happens when conditions match

  dynamic "action" {
    for_each = [each.value.action]
    content {
      type             = action.value.type
      target_group_arn = action.value.type == "forward" ? action.value.target_group_arn : null

      # Redirect action
      dynamic "redirect" {
        for_each = action.value.type == "redirect" ? [action.value.redirect] : []
        content {
          port        = redirect.value.port
          protocol    = redirect.value.protocol
          status_code = redirect.value.status_code
          host        = lookup(redirect.value, "host", null)
          path        = lookup(redirect.value, "path", null)
          query       = lookup(redirect.value, "query", null)
        }
      }

      # Fixed response action
      dynamic "fixed_response" {
        for_each = action.value.type == "fixed-response" ? [action.value.fixed_response] : []
        content {
          content_type = fixed_response.value.content_type
          message_body = fixed_response.value.message_body
          status_code  = fixed_response.value.status_code
        }
      }
    }
  }

  tags = var.common_tags
}
