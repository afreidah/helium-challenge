# KMS Module

## Overview

Creates AWS Key Management Service (KMS) customer managed keys with automatic rotation, configurable deletion protection, and optional alias support for encryption operations across AWS services. Provides full control over key lifecycle and access policies with CloudTrail audit logging for compliance.

## What It Does

- **KMS Customer Managed Key**: Encryption key for data protection with configurable rotation and deletion windows
- **KMS Alias**: Optional human-readable alias for easier key reference in applications and IAM policies
- **Key Rotation**: Automatic annual rotation when enabled (transparent to applications using the key)
- **Deletion Protection**: Minimum 7-day waiting period before deletion to prevent accidental key loss

## Key Features

- Customer managed keys with full lifecycle control
- Automatic key rotation enabled by default for enhanced security
- Configurable deletion window (7-30 days) for accidental deletion protection
- Custom key policy support for fine-grained access control
- Optional alias for easier key reference in code and policies
- CloudTrail audit logging for all key usage and management operations
- Multi-region key support when configured
- Checkov security scanner skip for rotation (controlled by variable)

## Module Position

This module provides encryption keys used by multiple AWS services:
```
**KMS Keys** → RDS/EBS/S3/Secrets Manager/Parameter Store/CloudWatch Logs
```

## Common Use Cases

- EBS volume encryption for EC2 instances
- S3 bucket server-side encryption
- RDS and Aurora database encryption at rest
- Secrets Manager secret encryption
- Parameter Store SecureString encryption
- CloudWatch Logs encryption
- Lambda environment variable encryption
- Cross-account encryption key sharing with custom policies

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering basic key creation without alias (description, rotation, deletion window, tags, no alias resource, null alias outputs), key with alias (alias creation, name format with 'alias/' prefix, alias name output), rotation disabled configuration, custom deletion window (7 days minimum), explicit key policy (policy content validation with kms:Encrypt and kms:Decrypt), tag verification (multiple custom tags), output shape validation both with and without alias
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Type-safe configuration with optional alias_name for conditional alias creation
- **Checkov Skip**: CKV_AWS_7 skipped for key rotation (controlled by enable_key_rotation variable with default true)
