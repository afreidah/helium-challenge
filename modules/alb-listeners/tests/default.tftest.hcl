# -----------------------------------------------------------------------------
# ALB LISTENERS MODULE TESTS
# -----------------------------------------------------------------------------
# Tests verify listener creation with proper routing and security configuration
# Run with: terraform test
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Test: HTTP listener with redirect to HTTPS
# -----------------------------------------------------------------------------
run "http_listener_redirect" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-listeners"
    alb_arn     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890abcdef"

    listeners = {
      http = {
        enabled  = true
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "redirect"
          redirect = {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
          }
        }
      }
      https = {
        enabled         = false
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        certificate_arn = null
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Not Found"
            status_code  = "404"
          }
        }
      }
    }

    listener_rules = {}

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify HTTP listener is created
  assert {
    condition     = length(aws_lb_listener.http) > 0
    error_message = "HTTP listener should be created when enabled"
  }

  # Verify redirect action
  assert {
    condition     = aws_lb_listener.http[0].default_action[0].type == "redirect"
    error_message = "HTTP listener should redirect to HTTPS"
  }
}

# -----------------------------------------------------------------------------
# Test: HTTPS listener with SSL certificate
# -----------------------------------------------------------------------------
run "https_listener_with_certificate" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-listeners"
    alb_arn     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890abcdef"

    listeners = {
      http = {
        enabled  = false
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "redirect"
          redirect = {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
          }
        }
      }
      https = {
        enabled         = true
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
        default_action = {
          type             = "forward"
          target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-tg/1234567890abcdef"
        }
      }
    }

    listener_rules = {}

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify HTTPS listener is created
  assert {
    condition     = length(aws_lb_listener.https) > 0
    error_message = "HTTPS listener should be created when enabled"
  }

  # Verify SSL policy
  assert {
    condition     = aws_lb_listener.https[0].ssl_policy == "ELBSecurityPolicy-TLS13-1-2-2021-06"
    error_message = "HTTPS listener should use TLS 1.3 security policy"
  }

  # Verify certificate is attached
  assert {
    condition     = aws_lb_listener.https[0].certificate_arn != null
    error_message = "HTTPS listener should have certificate attached"
  }
}

# -----------------------------------------------------------------------------
# Test: HTTP listener with forward action
# -----------------------------------------------------------------------------
run "http_listener_forward" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-listeners"
    alb_arn     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890abcdef"

    listeners = {
      http = {
        enabled  = true
        port     = 80
        protocol = "HTTP"
        default_action = {
          type             = "forward"
          target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/test-tg/1234567890abcdef"
        }
      }
      https = {
        enabled         = false
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        certificate_arn = null
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Not Found"
            status_code  = "404"
          }
        }
      }
    }

    listener_rules = {}

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify forward action
  assert {
    condition     = aws_lb_listener.http[0].default_action[0].type == "forward"
    error_message = "HTTP listener should forward to target group"
  }
}

# -----------------------------------------------------------------------------
# Test: Listener with fixed response (maintenance mode)
# -----------------------------------------------------------------------------
run "listener_fixed_response" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-listeners"
    alb_arn     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890abcdef"

    listeners = {
      http = {
        enabled  = true
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/html"
            message_body = "<h1>Under Maintenance</h1>"
            status_code  = "503"
          }
        }
      }
      https = {
        enabled         = false
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        certificate_arn = null
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Not Found"
            status_code  = "404"
          }
        }
      }
    }

    listener_rules = {}

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify fixed response action
  assert {
    condition     = aws_lb_listener.http[0].default_action[0].type == "fixed-response"
    error_message = "HTTP listener should return fixed response"
  }
}

# -----------------------------------------------------------------------------
# Test: Path-based routing rule
# -----------------------------------------------------------------------------
run "listener_rule_path_based" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-listeners"
    alb_arn     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890abcdef"

    listeners = {
      http = {
        enabled  = true
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Not Found"
            status_code  = "404"
          }
        }
      }
      https = {
        enabled         = false
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        certificate_arn = null
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Not Found"
            status_code  = "404"
          }
        }
      }
    }

    listener_rules = {
      api = {
        listener_protocol = "HTTP"
        priority          = 100
        conditions = [
          {
            type   = "path-pattern"
            values = ["/api/*"]
          }
        ]
        action = {
          type             = "forward"
          target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/api-tg/1234567890abcdef"
        }
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify listener rule is created
  assert {
    condition     = length(aws_lb_listener_rule.this) == 1
    error_message = "Listener rule should be created for path-based routing"
  }

  # Verify rule priority
  assert {
    condition     = aws_lb_listener_rule.this["api"].priority == 100
    error_message = "Listener rule should have correct priority"
  }
}

# -----------------------------------------------------------------------------
# Test: Host-based routing rule
# -----------------------------------------------------------------------------
run "listener_rule_host_based" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-listeners"
    alb_arn     = "arn:aws:elasticloadbalancing:us-east-1:123456789012:loadbalancer/app/test-alb/1234567890abcdef"

    listeners = {
      http = {
        enabled  = false
        port     = 80
        protocol = "HTTP"
        default_action = {
          type = "redirect"
          redirect = {
            port        = "443"
            protocol    = "HTTPS"
            status_code = "HTTP_301"
          }
        }
      }
      https = {
        enabled         = true
        port            = 443
        protocol        = "HTTPS"
        ssl_policy      = "ELBSecurityPolicy-TLS13-1-2-2021-06"
        certificate_arn = "arn:aws:acm:us-east-1:123456789012:certificate/12345678-1234-1234-1234-123456789012"
        default_action = {
          type = "fixed-response"
          fixed_response = {
            content_type = "text/plain"
            message_body = "Not Found"
            status_code  = "404"
          }
        }
      }
    }

    listener_rules = {
      app1 = {
        listener_protocol = "HTTPS"
        priority          = 10
        conditions = [
          {
            type   = "host-header"
            values = ["app1.example.com"]
          }
        ]
        action = {
          type             = "forward"
          target_group_arn = "arn:aws:elasticloadbalancing:us-east-1:123456789012:targetgroup/app1-tg/1234567890abcdef"
        }
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify host-based rule is created
  assert {
    condition     = length(aws_lb_listener_rule.this) == 1
    error_message = "Host-based listener rule should be created"
  }
}
