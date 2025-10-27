# -----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER MODULE TESTS
# -----------------------------------------------------------------------------
# Tests verify ALB creation with security defaults and proper configuration
# Run with: terraform test
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# Test: ALB with minimal configuration
# -----------------------------------------------------------------------------
run "alb_minimal_config" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb"

    alb_config = {
      name_suffix                      = "alb"
      load_balancer_type               = "application"
      internal                         = false
      enable_deletion_protection       = false
      enable_cross_zone_load_balancing = true
      enable_http2                     = true
      enable_waf_fail_open             = false
      desync_mitigation_mode           = "defensive"
      drop_invalid_header_fields       = true
      preserve_host_header             = true
      enable_xff_client_port           = false
      xff_header_processing_mode       = "append"
      idle_timeout                     = 60
      subnet_ids                       = ["subnet-12345", "subnet-67890"]
      security_group_ids               = ["sg-12345"]
      access_logs = {
        enabled = false
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify ALB is created with correct name
  assert {
    condition     = aws_lb.this.name == "test-alb"
    error_message = "ALB name should be prefixed with environment"
  }

  # Verify security defaults are applied
  assert {
    condition     = aws_lb.this.drop_invalid_header_fields == true
    error_message = "Invalid header fields should be dropped by default"
  }

  assert {
    condition     = aws_lb.this.desync_mitigation_mode == "defensive"
    error_message = "Desync mitigation should be defensive by default"
  }

  assert {
    condition     = aws_lb.this.enable_http2 == true
    error_message = "HTTP/2 should be enabled by default"
  }
}

# -----------------------------------------------------------------------------
# Test: ALB with deletion protection enabled (production)
# -----------------------------------------------------------------------------
run "alb_deletion_protection" {
  command = plan

  variables {
    environment = "production"
    region      = "us-east-1"
    component   = "alb"

    alb_config = {
      name_suffix                      = "alb"
      load_balancer_type               = "application"
      internal                         = false
      enable_deletion_protection       = true
      enable_cross_zone_load_balancing = true
      enable_http2                     = true
      enable_waf_fail_open             = false
      desync_mitigation_mode           = "defensive"
      drop_invalid_header_fields       = true
      preserve_host_header             = true
      enable_xff_client_port           = false
      xff_header_processing_mode       = "append"
      idle_timeout                     = 60
      subnet_ids                       = ["subnet-12345", "subnet-67890"]
      security_group_ids               = ["sg-12345"]
      access_logs = {
        enabled = false
      }
    }

    common_tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  # Verify deletion protection is enabled for production
  assert {
    condition     = aws_lb.this.enable_deletion_protection == true
    error_message = "Deletion protection should be enabled for production"
  }
}

# -----------------------------------------------------------------------------
# Test: ALB with access logs enabled
# -----------------------------------------------------------------------------
run "alb_access_logs" {
  command = plan

  variables {
    environment = "production"
    region      = "us-east-1"
    component   = "alb"

    alb_config = {
      name_suffix                      = "alb"
      load_balancer_type               = "application"
      internal                         = false
      enable_deletion_protection       = true
      enable_cross_zone_load_balancing = true
      enable_http2                     = true
      enable_waf_fail_open             = false
      desync_mitigation_mode           = "defensive"
      drop_invalid_header_fields       = true
      preserve_host_header             = true
      enable_xff_client_port           = false
      xff_header_processing_mode       = "append"
      idle_timeout                     = 60
      subnet_ids                       = ["subnet-12345", "subnet-67890"]
      security_group_ids               = ["sg-12345"]
      access_logs = {
        enabled = true
        bucket  = "my-alb-logs-bucket"
        prefix  = "production-alb"
      }
    }

    common_tags = {
      Environment = "production"
      ManagedBy   = "Terraform"
    }
  }

  # Verify access logs configuration
  assert {
    condition     = length(aws_lb.this.access_logs) > 0
    error_message = "Access logs should be configured when enabled"
  }
}

# -----------------------------------------------------------------------------
# Test: Internal ALB configuration
# -----------------------------------------------------------------------------
run "alb_internal" {
  command = plan

  variables {
    environment = "test"
    region      = "us-east-1"
    component   = "alb"

    alb_config = {
      name_suffix                      = "internal-alb"
      load_balancer_type               = "application"
      internal                         = true
      enable_deletion_protection       = false
      enable_cross_zone_load_balancing = true
      enable_http2                     = true
      enable_waf_fail_open             = false
      desync_mitigation_mode           = "defensive"
      drop_invalid_header_fields       = true
      preserve_host_header             = true
      enable_xff_client_port           = false
      xff_header_processing_mode       = "append"
      idle_timeout                     = 60
      subnet_ids                       = ["subnet-12345", "subnet-67890"]
      security_group_ids               = ["sg-12345"]
      access_logs = {
        enabled = false
      }
    }

    common_tags = {
      Environment = "test"
      ManagedBy   = "Terraform"
    }
  }

  # Verify internal ALB is properly configured
  assert {
    condition     = aws_lb.this.internal == true
    error_message = "ALB should be internal when configured"
  }
}
