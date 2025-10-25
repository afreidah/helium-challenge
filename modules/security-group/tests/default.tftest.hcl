# -----------------------------------------------------------------------------
# SECURITY GROUP MODULE TEST SUITE
# -----------------------------------------------------------------------------
#
# Focused tests validating critical logic paths and computed values. Tests
# avoid redundant input echo validation and focus on interpolation logic,
# rule count variations, and edge cases.
#
# Test Coverage:
# - Name prefix interpolation (environment + name_suffix)
# - Tag merging with Name tag generation
# - Empty rule sets (no egress for databases)
# - Rule count validation for different scenarios
# - VPC association
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# TEST DEFAULTS AND MOCK VALUES
# -----------------------------------------------------------------------------

variables {
  vpc_id      = "vpc-12345678"
  environment = "production"
  region      = "us-east-1"

  tags = {
    Env  = "test"
    Team = "netops"
  }
}

# -----------------------------------------------------------------------------
# NAME INTERPOLATION AND TAG MERGING TEST
# -----------------------------------------------------------------------------
# Validates that name_prefix is correctly constructed and tags are merged

run "name_and_tag_interpolation" {
  command = plan

  variables {
    environment = "staging"
    security_group_rules = {
      name_suffix   = "alb"
      description   = "Security group for Application Load Balancer"
      ingress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS from anywhere"
        }
      ]
      egress_rules = []
    }
    tags = {
      CustomTag = "custom-value"
    }
  }

  assert {
    condition     = aws_security_group.this.name_prefix == "staging-alb-"
    error_message = "Name prefix should be environment-name_suffix-"
  }
  assert {
    condition     = aws_security_group.this.tags["Name"] == "staging-alb"
    error_message = "Name tag should be environment-name_suffix without trailing dash"
  }
  assert {
    condition     = aws_security_group.this.tags["CustomTag"] == "custom-value"
    error_message = "Custom tags should be merged"
  }
}

# -----------------------------------------------------------------------------
# RULE COUNT VALIDATION - MULTIPLE INGRESS
# -----------------------------------------------------------------------------
# Validates correct iteration over multiple ingress rules

run "multiple_ingress_rules" {
  command = plan

  variables {
    security_group_rules = {
      name_suffix   = "alb"
      description   = "ALB security group"
      ingress_rules = [
        {
          from_port   = 80
          to_port     = 80
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTP"
        },
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS"
        },
        {
          from_port   = 8080
          to_port     = 8080
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "Alt HTTP"
        }
      ]
      egress_rules = [
        {
          from_port   = 0
          to_port     = 0
          protocol    = "-1"
          cidr_blocks = ["0.0.0.0/0"]
          description = "All egress"
        }
      ]
    }
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 3
    error_message = "Should create exactly 3 ingress rules"
  }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.this) == 1
    error_message = "Should create exactly 1 egress rule"
  }
}

# -----------------------------------------------------------------------------
# EMPTY EGRESS RULES TEST
# -----------------------------------------------------------------------------
# Validates security group with no egress rules (database pattern)

run "no_egress_rules" {
  command = plan

  variables {
    security_group_rules = {
      name_suffix   = "aurora-postgresql"
      description   = "Aurora security group"
      ingress_rules = [
        {
          from_port   = 5432
          to_port     = 5432
          protocol    = "tcp"
          cidr_blocks = ["10.0.0.0/16"]
          description = "PostgreSQL"
        }
      ]
      egress_rules = []
    }
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 1
    error_message = "Should create 1 ingress rule"
  }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.this) == 0
    error_message = "Should create 0 egress rules when empty list provided"
  }
}

# -----------------------------------------------------------------------------
# EMPTY INGRESS RULES TEST
# -----------------------------------------------------------------------------
# Validates security group with no ingress rules (egress-only pattern)

run "no_ingress_rules" {
  command = plan

  variables {
    security_group_rules = {
      name_suffix   = "lambda-egress"
      description   = "Lambda egress only"
      ingress_rules = []
      egress_rules = [
        {
          from_port   = 443
          to_port     = 443
          protocol    = "tcp"
          cidr_blocks = ["0.0.0.0/0"]
          description = "HTTPS egress"
        }
      ]
    }
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "Should create 0 ingress rules when empty list provided"
  }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.this) == 1
    error_message = "Should create 1 egress rule"
  }
}

# -----------------------------------------------------------------------------
# COMPLETELY EMPTY RULES TEST
# -----------------------------------------------------------------------------
# Validates security group with no rules at all

run "no_rules_at_all" {
  command = plan

  variables {
    security_group_rules = {
      name_suffix   = "placeholder"
      description   = "Placeholder security group"
      ingress_rules = []
      egress_rules  = []
    }
  }

  assert {
    condition     = length(aws_vpc_security_group_ingress_rule.this) == 0
    error_message = "Should create 0 ingress rules"
  }
  assert {
    condition     = length(aws_vpc_security_group_egress_rule.this) == 0
    error_message = "Should create 0 egress rules"
  }
  assert {
    condition     = aws_security_group.this.vpc_id == var.vpc_id
    error_message = "Security group should still be created in VPC even with no rules"
  }
}

# -----------------------------------------------------------------------------
# VPC ASSOCIATION TEST
# -----------------------------------------------------------------------------
# Validates security group is created in correct VPC

run "vpc_association" {
  command = plan

  variables {
    vpc_id = "vpc-different123"
    security_group_rules = {
      name_suffix   = "test"
      description   = "Test"
      ingress_rules = []
      egress_rules  = []
    }
  }

  assert {
    condition     = aws_security_group.this.vpc_id == "vpc-different123"
    error_message = "Security group should be created in the specified VPC"
  }
}
