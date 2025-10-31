# IAM Role Module

## Overview

Creates AWS IAM roles with configurable trust policies, managed policy attachments, inline policies, and optional EC2 instance profiles. Designed for centralized role configuration in root.hcl with automatic environment-based naming and consistent deployment across environments. Supports any AWS service principal including EKS, Lambda, ECS, and cross-account access patterns.

## What It Does

- **IAM Role**: Identity with trust policy defining who/what can assume the role
- **Managed Policy Attachments**: AWS managed or customer managed policies granting specific permissions
- **Inline Policies**: Policies embedded directly in the role (non-reusable)
- **Instance Profile**: Optional EC2 instance profile for attaching role to instances (EKS nodes, EC2)

## Key Features

- Centralized role configuration via `role_config` object from root.hcl
- Automatic name prefixing with environment (`${environment}-${name_suffix}`)
- Multiple managed policy attachments with `for_each` iteration
- Multiple inline policies with `for_each` iteration
- Conditional instance profile creation (`create_instance_profile` flag)
- Supports any AWS service principal (eks.amazonaws.com, ec2.amazonaws.com, lambda.amazonaws.com, ecs-tasks.amazonaws.com)
- Supports cross-account access with AWS principal ARNs
- Consistent tagging with automatic Name tag generation
- JSON trust policy validation via `assume_role_policy`

## Module Position

This module provides the identity and permissions layer for AWS resources:
```
**IAM Role** → Assume Role → AWS Service/User → Access AWS Resources
```

## Common Use Cases

- EKS Cluster Roles: Control plane service permissions
- EKS Node Roles: Worker node permissions with instance profile
- Lambda Execution Roles: Grant Lambda function AWS API access
- ECS Task Roles: Container application permissions
- Cross-Account Roles: Enable multi-account architectures
- Service Roles: Allow AWS services to act on your behalf
- SSM-enabled roles: Session Manager access without SSH keys
- Custom roles with inline policies for specific use cases

## Testing & Validation

- **Terraform Tests**: Focused test suite covering name interpolation (`${environment}-${name_suffix}`), tag merging with automatic Name tag, multiple policy attachment counts (0, 1, 3+ policies), conditional instance profile creation (created/not created based on flag), instance profile naming matches role name, trust policy validation (EKS service principal, sts:AssumeRole action), and output validation (role_name, instance_profile_name null/non-null based on flag)
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Environment must be one of (production/staging/development/prod/stage/dev), region format validation (us-east-1 pattern), name_suffix length (1-50 chars), description length (1-1000 chars), tag key/value length limits (128/256 chars)
- **Centralized Configuration**: Role definitions in root.hcl allow easy template reuse across environments
- **Inline vs Managed Policies**: Use inline policies for role-specific permissions, managed policies for shared permissions across roles
