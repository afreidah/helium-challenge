# -----------------------------------------------------------------------------
# IAM ROLE MODULE
# -----------------------------------------------------------------------------
#
# This module creates an AWS IAM role with configurable trust policy, managed
# policy attachments, and optional EC2 instance profile. Designed for EKS
# cluster and node roles with appropriate trust relationships and permissions.
#
# The role configuration is passed as a single object from root.hcl, making
# it easy to define role templates centrally and deploy them consistently
# across environments with automatic environment-based naming.
#
# Components Created:
#   - IAM Role: Identity with trust policy for AWS services or users
#   - Policy Attachments: AWS managed or custom policies for permissions
#   - Instance Profile: Optional EC2 instance profile for role attachment
#
# Features:
#   - Centralized role configuration in root.hcl
#   - Automatic name prefixing with environment
#   - Multiple managed policy attachments support
#   - Optional instance profile for EC2/EKS node use cases
#   - Consistent tagging across all resources
#   - Supports any AWS service principal
#
# Common Use Cases:
#   - EKS Cluster Roles: Control plane permissions and service integration
#   - EKS Node Roles: Worker node permissions with instance profile
#   - Lambda Execution Roles: Grant Lambda function permissions
#   - ECS Task Roles: Provide permissions to containerized applications
#   - Cross-Account Roles: Enable cross-account access patterns
#   - Service Roles: Allow AWS services to act on your behalf
#
# Security Model:
#   - Trust Policy: Defines who/what can assume the role
#   - Managed Policies: Grant specific AWS service permissions
#   - Least Privilege: Attach only required policies
#   - Instance Profile: EC2-specific role attachment mechanism
#
# IMPORTANT:
#   - Trust policy must be valid JSON and include sts:AssumeRole action
#   - Policy ARNs must exist before attachment
#   - Instance profile only needed for EC2/EKS node use cases
#   - Role name automatically prefixed with environment for uniqueness
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# IAM ROLE
# -----------------------------------------------------------------------------
# IAM role with configurable trust policy
# Defines identity that can be assumed by specified principals
# Name is automatically prefixed with environment

resource "aws_iam_role" "this" {
  name               = "${var.environment}-${var.role_config.name_suffix}"
  description        = var.role_config.description
  assume_role_policy = var.role_config.assume_role_policy

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.role_config.name_suffix}"
    }
  )
}

# -----------------------------------------------------------------------------
# MANAGED POLICY ATTACHMENTS
# -----------------------------------------------------------------------------
# Attach AWS managed or customer managed policies to role
# Grants permissions defined in the policies to role principals
# Uses for_each for better resource management

resource "aws_iam_role_policy_attachment" "this" {
  for_each = toset(var.role_config.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = each.value
}

# -----------------------------------------------------------------------------
# INLINE POLICIES
# -----------------------------------------------------------------------------
# Inline policies attached directly to the role
# Used when policies don't need to be shared across roles

resource "aws_iam_role_policy" "inline" {
  for_each = var.role_config.inline_policies

  name   = each.key
  role   = aws_iam_role.this.id
  policy = each.value
}

# -----------------------------------------------------------------------------
# INSTANCE PROFILE (EC2)
# -----------------------------------------------------------------------------
# Instance profile for attaching role to EC2 instances (EKS nodes)
# Only created when create_instance_profile is true
# Name matches role name for consistency

resource "aws_iam_instance_profile" "this" {
  count = var.role_config.create_instance_profile ? 1 : 0

  name = "${var.environment}-${var.role_config.name_suffix}"
  role = aws_iam_role.this.name

  tags = merge(
    var.tags,
    {
      Name = "${var.environment}-${var.role_config.name_suffix}"
    }
  )
}
