# -----------------------------------------------------------------------------
# ALB TARGET GROUPS MODULE TESTS
# -----------------------------------------------------------------------------
# Tests verify target group creation with proper health checks and configuration
# Run with: terraform test
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Test: Target group with instance target type
# -----------------------------------------------------------------------------
run "target_group_instance_type" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-target-groups"
    vpc_id      = "vpc-12345678"

    target_groups = {
      app = {
        port                 = 8080
        protocol             = "HTTP"
        target_type          = "instance"
        deregistration_delay = 30
        health_check = {
          enabled             = true
          healthy_threshold   = 2
          interval            = 30
          matcher             = "200"
          path                = "/health"
          port                = "traffic-port"
          protocol            = "HTTP"
          timeout             = 5
          unhealthy_threshold = 2
        }
        stickiness = null
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify target group is created with correct type
  assert {
    condition     = aws_lb_target_group.this["app"].target_type == "instance"
    error_message = "Target group should use instance target type"
  }

  # Verify health check is configured
  assert {
    condition     = aws_lb_target_group.this["app"].health_check[0].enabled == true
    error_message = "Health check should be enabled"
  }

  assert {
    condition     = aws_lb_target_group.this["app"].health_check[0].path == "/health"
    error_message = "Health check path should match configuration"
  }
}

# -----------------------------------------------------------------------------
# Test: Target group with IP target type (for EKS pods)
# -----------------------------------------------------------------------------
run "target_group_ip_type" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-target-groups"
    vpc_id      = "vpc-12345678"

    target_groups = {
      pods = {
        port                 = 8080
        protocol             = "HTTP"
        target_type          = "ip"
        deregistration_delay = 30
        health_check = {
          enabled             = true
          healthy_threshold   = 2
          interval            = 30
          matcher             = "200"
          path                = "/health"
          port                = "traffic-port"
          protocol            = "HTTP"
          timeout             = 5
          unhealthy_threshold = 2
        }
        stickiness = null
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify target group uses IP target type
  assert {
    condition     = aws_lb_target_group.this["pods"].target_type == "ip"
    error_message = "Target group should use IP target type for pods"
  }
}

# -----------------------------------------------------------------------------
# Test: Target group with session stickiness
# -----------------------------------------------------------------------------
run "target_group_stickiness" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-target-groups"
    vpc_id      = "vpc-12345678"

    target_groups = {
      app = {
        port                 = 8080
        protocol             = "HTTP"
        target_type          = "instance"
        deregistration_delay = 30
        health_check = {
          enabled             = true
          healthy_threshold   = 2
          interval            = 30
          matcher             = "200"
          path                = "/health"
          port                = "traffic-port"
          protocol            = "HTTP"
          timeout             = 5
          unhealthy_threshold = 2
        }
        stickiness = {
          enabled         = true
          type            = "lb_cookie"
          cookie_duration = 86400
        }
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify stickiness is configured
  assert {
    condition     = length(aws_lb_target_group.this["app"].stickiness) > 0
    error_message = "Stickiness should be configured when provided"
  }
}

# -----------------------------------------------------------------------------
# Test: Multiple target groups
# -----------------------------------------------------------------------------
run "multiple_target_groups" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb-target-groups"
    vpc_id      = "vpc-12345678"

    target_groups = {
      app = {
        port                 = 8080
        protocol             = "HTTP"
        target_type          = "instance"
        deregistration_delay = 30
        health_check = {
          enabled             = true
          healthy_threshold   = 2
          interval            = 30
          matcher             = "200"
          path                = "/health"
          port                = "traffic-port"
          protocol            = "HTTP"
          timeout             = 5
          unhealthy_threshold = 2
        }
        stickiness = null
      }
      api = {
        port                 = 8081
        protocol             = "HTTP"
        target_type          = "ip"
        deregistration_delay = 60
        health_check = {
          enabled             = true
          healthy_threshold   = 3
          interval            = 60
          matcher             = "200-299"
          path                = "/api/health"
          port                = "traffic-port"
          protocol            = "HTTP"
          timeout             = 10
          unhealthy_threshold = 3
        }
        stickiness = null
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify both target groups are created
  assert {
    condition     = length(aws_lb_target_group.this) == 2
    error_message = "Should create two target groups"
  }

  # Verify different configurations
  assert {
    condition     = aws_lb_target_group.this["app"].port == 8080 && aws_lb_target_group.this["api"].port == 8081
    error_message = "Target groups should have independent port configurations"
  }
}

# -----------------------------------------------------------------------------
# Test: Target group name truncation (32 char limit)
# -----------------------------------------------------------------------------
run "target_group_name_truncation" {
  command = plan

  variables {
    environment = "production"
    region      = "us-east-1"
    component   = "alb-target-groups"
    vpc_id      = "vpc-12345678"

    target_groups = {
      very-long-application-name = {
        port                 = 8080
        protocol             = "HTTP"
        target_type          = "instance"
        deregistration_delay = 30
        health_check = {
          enabled             = true
          healthy_threshold   = 2
          interval            = 30
          matcher             = "200"
          path                = "/health"
          port                = "traffic-port"
          protocol            = "HTTP"
          timeout             = 5
          unhealthy_threshold = 2
        }
        stickiness = null
      }
    }

    common_tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  # Verify name is truncated to 32 characters
  assert {
    condition     = length(aws_lb_target_group.this["very-long-application-name"].name) <= 32
    error_message = "Target group name should be truncated to 32 characters"
  }
}
