# -----------------------------------------------------------------------------
# ALB MODULE - TEST SUITE
# -----------------------------------------------------------------------------
#
# Author: Alex
# Module: terraform-aws-alb
# Purpose: Validates Application Load Balancer module logic and computed values
#
# Description:
#   Test suite for the ALB Terraform module, focusing on conditional logic,
#   computed values, and resource relationships. Tests verify that the module
#   correctly implements business logic such as HTTPS redirect behavior,
#   conditional resource creation, and proper default value application.
#
# Test Philosophy:
#   - Tests validate LOGIC, not input passthrough
#   - Focuses on conditional resource creation (HTTPS listener, redirects)
#   - Verifies computed/derived values, not simple input assignments
#   - Uses Terraform's native test framework with plan-only execution
#   - No actual AWS infrastructure deployment required
#
# Test Coverage:
#   ✓ HTTP-to-HTTPS redirect logic based on certificate presence
#   ✓ Conditional HTTPS listener creation
#   ✓ Multiple target group creation and iteration
#   ✓ Default action type selection (forward vs redirect)
#   ✓ Security policy application on HTTPS listeners
#   ✓ Stickiness configuration propagation
#   ✓ Type conversions and numeric value handling
#
# Usage:
#   terraform test                    # Run all tests
#   terraform test -filter=https      # Run specific test pattern
#   terraform test -verbose           # Show detailed output
#
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# TEST: HTTP Listener Forwards Without Certificate
# -----------------------------------------------------------------------------
# Validates that HTTP listener uses forward action when no certificate provided
# This tests the conditional logic: certificate == null → forward action

run "http_forwards_without_certificate" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]
      certificate_arn    = null

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
      }
    }
  }

  # Verify HTTP listener uses forward action (not redirect)
  assert {
    condition     = length([for action in aws_lb_listener.http.default_action : action if action.type == "forward"]) > 0
    error_message = "HTTP listener should forward to target group when no certificate provided"
  }

  # Verify HTTPS listener is NOT created without certificate
  assert {
    condition     = length(aws_lb_listener.https) == 0
    error_message = "HTTPS listener should not be created without certificate"
  }
}

# -----------------------------------------------------------------------------
# TEST: HTTP-to-HTTPS Redirect With Certificate
# -----------------------------------------------------------------------------
# Validates that HTTP listener redirects to HTTPS when certificate provided
# This tests the conditional logic: certificate != null → redirect action

run "http_redirects_with_certificate" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]
      certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
      }
    }
  }

  # Verify HTTP listener uses redirect action (not forward)
  assert {
    condition     = length([for action in aws_lb_listener.http.default_action : action if action.type == "redirect"]) > 0
    error_message = "HTTP listener should redirect to HTTPS when certificate provided"
  }

  # Verify redirect targets HTTPS port 443
  assert {
    condition     = try(aws_lb_listener.http.default_action[0].redirect[0].port, "") == "443"
    error_message = "HTTP redirect should target port 443"
  }

  # Verify redirect uses permanent 301 status
  assert {
    condition     = try(aws_lb_listener.http.default_action[0].redirect[0].status_code, "") == "HTTP_301"
    error_message = "HTTP redirect should use 301 permanent status code"
  }

  # Verify HTTPS listener IS created with certificate
  assert {
    condition     = length(aws_lb_listener.https) == 1
    error_message = "HTTPS listener should be created when certificate provided"
  }
}

# -----------------------------------------------------------------------------
# TEST: HTTPS Listener Configuration
# -----------------------------------------------------------------------------
# Validates computed HTTPS listener properties when certificate is provided

run "https_listener_configuration" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]
      certificate_arn    = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
      }
    }
  }

  # Verify HTTPS listener uses standard HTTPS port
  assert {
    condition     = aws_lb_listener.https["https"].port == 443
    error_message = "HTTPS listener should use port 443"
  }

  # Verify HTTPS listener uses HTTPS protocol
  assert {
    condition     = aws_lb_listener.https["https"].protocol == "HTTPS"
    error_message = "HTTPS listener should use HTTPS protocol"
  }

  # Verify secure TLS policy is applied (TLS 1.2 minimum)
  assert {
    condition     = aws_lb_listener.https["https"].ssl_policy == "ELBSecurityPolicy-TLS-1-2-2017-01"
    error_message = "HTTPS listener should enforce TLS 1.2 minimum security policy"
  }

  # Verify HTTPS listener has forward action
  assert {
    condition     = length([for action in aws_lb_listener.https["https"].default_action : action if action.type == "forward"]) > 0
    error_message = "HTTPS listener should forward traffic to target group"
  }
}

# -----------------------------------------------------------------------------
# TEST: Multiple Target Groups
# -----------------------------------------------------------------------------
# Validates that multiple target groups are created from map iteration

run "multiple_target_groups" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
        api = {
          port         = 8081
          protocol     = "HTTP"
          target_type  = "ip"
          health_check = {
            path = "/api/health"
          }
        }
        admin = {
          port         = 8082
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
      }
    }
  }

  # Verify correct number of target groups created
  assert {
    condition     = length(aws_lb_target_group.this) == 3
    error_message = "Should create exactly 3 target groups from map"
  }

  # Verify all target group keys exist
  assert {
    condition     = contains(keys(aws_lb_target_group.this), "app") && contains(keys(aws_lb_target_group.this), "api") && contains(keys(aws_lb_target_group.this), "admin")
    error_message = "All target group keys (app, api, admin) should exist"
  }
}

# -----------------------------------------------------------------------------
# TEST: Stickiness Configuration
# -----------------------------------------------------------------------------
# Validates that stickiness block is properly configured when enabled

run "stickiness_enabled" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
          stickiness = {
            enabled         = true
            type            = "lb_cookie"
            cookie_duration = 3600
          }
        }
      }
    }
  }

  # Verify stickiness block exists and is enabled
  assert {
    condition     = length(aws_lb_target_group.this["app"].stickiness) > 0 && aws_lb_target_group.this["app"].stickiness[0].enabled == true
    error_message = "Stickiness should be enabled when configured"
  }

  # Verify stickiness type is set correctly
  assert {
    condition     = aws_lb_target_group.this["app"].stickiness[0].type == "lb_cookie"
    error_message = "Stickiness type should be lb_cookie"
  }
}

# -----------------------------------------------------------------------------
# TEST: Deregistration Delay Type Conversion
# -----------------------------------------------------------------------------
# Validates that deregistration_delay is properly handled as numeric value

run "deregistration_delay_numeric" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]

      target_groups = {
        app = {
          port                 = 8080
          protocol             = "HTTP"
          target_type          = "instance"
          deregistration_delay = 60
          health_check         = {}
        }
      }
    }
  }

  # Verify deregistration delay is numeric and equals expected value
  assert {
    condition     = tonumber(aws_lb_target_group.this["app"].deregistration_delay) == 60
    error_message = "Target group deregistration delay should be 60 seconds"
  }
}

# -----------------------------------------------------------------------------
# TEST: Health Check Protocol Defaults
# -----------------------------------------------------------------------------
# Validates that health check protocol defaults to target group protocol

run "health_check_protocol_default" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {
            path = "/health"
            # protocol not specified, should default to "HTTP"
          }
        }
      }
    }
  }

  # Verify health check protocol defaults to HTTP when target uses HTTP
  assert {
    condition     = aws_lb_target_group.this["app"].health_check[0].protocol == "HTTP"
    error_message = "Health check protocol should default to HTTP"
  }
}

# -----------------------------------------------------------------------------
# TEST: Cross-Zone Load Balancing Default
# -----------------------------------------------------------------------------
# Validates that cross-zone load balancing is enabled by default for ALB

run "cross_zone_default_enabled" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
      }
    }
  }

  # Verify ALB has cross-zone enabled (or null, which means enabled for ALB)
  # For ALB, cross-zone is enabled by default and may show as null in plan
  assert {
    condition     = aws_lb.this.enable_cross_zone_load_balancing == true || aws_lb.this.enable_cross_zone_load_balancing == null
    error_message = "Cross-zone load balancing should be enabled or null (default enabled for ALB)"
  }
}

# -----------------------------------------------------------------------------
# TEST: Target Group Name Construction
# -----------------------------------------------------------------------------
# Validates that target group names are properly constructed with prefix

run "target_group_name_construction" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "myapp"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]

      target_groups = {
        frontend = {
          port         = 80
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
      }
    }
  }

  # Verify target group name starts with environment-name_suffix prefix
  assert {
    condition     = can(regex("^dev-myapp-", aws_lb_target_group.this["frontend"].name))
    error_message = "Target group name should start with environment-name_suffix prefix"
  }
}

# -----------------------------------------------------------------------------
# TEST: HTTP/2 Default Enabled
# -----------------------------------------------------------------------------
# Validates that HTTP/2 is enabled by default for better performance

run "http2_default_enabled" {
  command = plan

  variables {
    environment = "dev"
    region      = "us-east-1"
    vpc_id      = "vpc-12345678"

    alb_config = {
      name_suffix        = "app"
      internal           = false
      subnet_ids         = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
      security_group_ids = ["sg-12345678"]

      target_groups = {
        app = {
          port         = 8080
          protocol     = "HTTP"
          target_type  = "instance"
          health_check = {}
        }
      }
    }
  }

  # Verify HTTP/2 is enabled by default
  assert {
    condition     = aws_lb.this.enable_http2 == true
    error_message = "HTTP/2 should be enabled by default"
  }
}
