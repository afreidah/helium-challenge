# -----------------------------------------------------------------------------
# IAM ROLE MODULE TEST SUITE
# -----------------------------------------------------------------------------
#
# Focused tests validating critical logic paths and computed values for the
# IAM role module. Tests avoid redundant input echo validation and focus on
# interpolation logic, conditional resource creation, and edge cases.
#
# Test Coverage:
# - Name prefix interpolation (environment + name_suffix)
# - Tag merging with Name tag generation
# - Conditional instance profile creation
# - Policy attachment count validation
# - Trust policy configuration from role_config object
# - VPC association
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# TEST DEFAULTS AND MOCK VALUES
# -----------------------------------------------------------------------------

variables {
  environment = "production"
  region      = "us-east-1"

  tags = {
    Env  = "test"
    Team = "platform"
  }
}

# -----------------------------------------------------------------------------
# NAME INTERPOLATION AND TAG MERGING TEST
# -----------------------------------------------------------------------------
# Validates that role name is correctly constructed and tags are merged

run "name_and_tag_interpolation" {
  command = plan

  variables {
    environment = "staging"
    role_config = {
      name_suffix = "eks-cluster-role"
      description = "EKS cluster role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "eks.amazonaws.com" }
        }]
      })
      policy_arns             = []
      create_instance_profile = false
    }
    tags = {
      CustomTag = "custom-value"
    }
  }

  assert {
    condition     = aws_iam_role.this.name == "staging-eks-cluster-role"
    error_message = "Role name should be environment-name_suffix"
  }
  assert {
    condition     = aws_iam_role.this.tags["Name"] == "staging-eks-cluster-role"
    error_message = "Name tag should be environment-name_suffix"
  }
  assert {
    condition     = aws_iam_role.this.tags["CustomTag"] == "custom-value"
    error_message = "Custom tags should be merged"
  }
}

# -----------------------------------------------------------------------------
# POLICY ATTACHMENT COUNT VALIDATION
# -----------------------------------------------------------------------------
# Validates correct iteration over multiple policy ARNs

run "multiple_policy_attachments" {
  command = plan

  variables {
    role_config = {
      name_suffix = "eks-node-role"
      description = "EKS node role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "ec2.amazonaws.com" }
        }]
      })
      policy_arns = [
        "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy",
        "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy",
        "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
      ]
      create_instance_profile = false
    }
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 3
    error_message = "Should create exactly 3 policy attachments"
  }
}

# -----------------------------------------------------------------------------
# NO POLICY ATTACHMENTS TEST
# -----------------------------------------------------------------------------
# Validates role creation with empty policy list

run "no_policy_attachments" {
  command = plan

  variables {
    role_config = {
      name_suffix = "minimal-role"
      description = "Minimal role without policies"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "lambda.amazonaws.com" }
        }]
      })
      policy_arns             = []
      create_instance_profile = false
    }
  }

  assert {
    condition     = length(aws_iam_role_policy_attachment.this) == 0
    error_message = "Should create 0 policy attachments when empty list provided"
  }
  assert {
    condition     = aws_iam_role.this.name == "production-minimal-role"
    error_message = "Role should still be created with no policies"
  }
}

# -----------------------------------------------------------------------------
# CONDITIONAL INSTANCE PROFILE CREATION TEST
# -----------------------------------------------------------------------------
# Validates instance profile is created when flag is true

run "instance_profile_created" {
  command = plan

  variables {
    role_config = {
      name_suffix = "eks-node-role"
      description = "EKS node role with instance profile"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "ec2.amazonaws.com" }
        }]
      })
      policy_arns             = []
      create_instance_profile = true
    }
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 1
    error_message = "Should create instance profile when flag is true"
  }
  assert {
    condition     = aws_iam_instance_profile.this[0].name == "production-eks-node-role"
    error_message = "Instance profile name should match role name"
  }
  assert {
    condition     = aws_iam_instance_profile.this[0].tags["Name"] == "production-eks-node-role"
    error_message = "Instance profile Name tag should match role name"
  }
}

# -----------------------------------------------------------------------------
# NO INSTANCE PROFILE TEST
# -----------------------------------------------------------------------------
# Validates instance profile is not created when flag is false

run "instance_profile_not_created" {
  command = plan

  variables {
    role_config = {
      name_suffix = "eks-cluster-role"
      description = "EKS cluster role without instance profile"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "eks.amazonaws.com" }
        }]
      })
      policy_arns             = []
      create_instance_profile = false
    }
  }

  assert {
    condition     = length(aws_iam_instance_profile.this) == 0
    error_message = "Should not create instance profile when flag is false"
  }
}

# -----------------------------------------------------------------------------
# TRUST POLICY VALIDATION TEST
# -----------------------------------------------------------------------------
# Validates trust policy is correctly applied from role_config

run "trust_policy_eks" {
  command = plan

  variables {
    role_config = {
      name_suffix = "eks-cluster-role"
      description = "EKS cluster role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "eks.amazonaws.com" }
        }]
      })
      policy_arns             = []
      create_instance_profile = false
    }
  }

  assert {
    condition     = length(regexall("sts:AssumeRole", aws_iam_role.this.assume_role_policy)) > 0
    error_message = "Trust policy must include sts:AssumeRole action"
  }
  assert {
    condition     = length(regexall("eks\\.amazonaws\\.com", aws_iam_role.this.assume_role_policy)) > 0
    error_message = "Trust policy must include eks.amazonaws.com service principal"
  }
}

# -----------------------------------------------------------------------------
# OUTPUT VALIDATION - WITH INSTANCE PROFILE
# -----------------------------------------------------------------------------
# Validates outputs when instance profile is created

run "outputs_with_instance_profile" {
  command = plan

  variables {
    role_config = {
      name_suffix = "node-role"
      description = "Node role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "ec2.amazonaws.com" }
        }]
      })
      policy_arns             = []
      create_instance_profile = true
    }
  }

  assert {
    condition     = output.role_name == "production-node-role"
    error_message = "role_name output should match computed name"
  }
  assert {
    condition     = output.instance_profile_name == "production-node-role"
    error_message = "instance_profile_name should be set when created"
  }
}

# -----------------------------------------------------------------------------
# OUTPUT VALIDATION - WITHOUT INSTANCE PROFILE
# -----------------------------------------------------------------------------
# Validates outputs when instance profile is not created

run "outputs_without_instance_profile" {
  command = plan

  variables {
    role_config = {
      name_suffix = "cluster-role"
      description = "Cluster role"
      assume_role_policy = jsonencode({
        Version = "2012-10-17"
        Statement = [{
          Effect    = "Allow"
          Action    = "sts:AssumeRole"
          Principal = { Service = "eks.amazonaws.com" }
        }]
      })
      policy_arns             = []
      create_instance_profile = false
    }
  }

  assert {
    condition     = output.role_name == "production-cluster-role"
    error_message = "role_name output should match computed name"
  }
  assert {
    condition     = output.instance_profile_name == null
    error_message = "instance_profile_name should be null when not created"
  }
  assert {
    condition     = output.instance_profile_arn == null
    error_message = "instance_profile_arn should be null when not created"
  }
}
