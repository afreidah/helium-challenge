# Secrets Manager Module

## Overview

Creates AWS Secrets Manager secrets with optional automatic rotation for RDS databases. Secrets are encrypted using KMS and support versioning, recovery windows, and cross-region replication. The module provides zero-downtime rotation using AWS Lambda functions that update both database passwords and secret values simultaneously.

## What It Does

- **Secret**: Container for secret versions and metadata with KMS encryption
- **Secret Version**: Actual secret value (JSON or plaintext) with staging labels for version management
- **Rotation Configuration**: Optional Lambda-based rotation schedule for automatic credential rotation
- **IAM Read Policy**: Optional read access policy for service principals (EKS pods, Lambda functions)

## Key Features

- KMS encryption for all secret values
- Automatic rotation for RDS, Redshift, and DocumentDB credentials (requires Lambda function with VPC access)
- Version management with staging labels (AWSCURRENT, AWSPENDING)
- Recovery window for accidental deletion (7-30 days, minimum 7 days required)
- Cross-region replication for disaster recovery scenarios
- Optional IAM read policy generation for service principals
- Map-based secret creation (multiple secrets in single module call)
- Tag merging with automatic Name tag from secret path
- Policy name format: `{prefix}-read-secrets` for IAM policy

## Module Position

This module provides encrypted credential storage for applications and databases:
```
**Secrets Manager** → EKS Pods/Lambda Functions → RDS/Application Configuration
```

## Common Use Cases

- Aurora PostgreSQL database credentials with automatic rotation
- RDS master passwords with Lambda-based rotation
- Application API keys and configuration secrets
- Service account credentials for external APIs
- Microservices configuration with per-environment secrets
- EKS pod IAM policies for reading application secrets

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering basic secret creation (secret and version resources with default 30-day recovery window), multiple secrets (3 independent secrets with different configurations), custom recovery window (7-day minimum), KMS encryption (secret using specified KMS key), rotation enabled (rotation resource created when Lambda ARN provided with 30-day schedule), rotation disabled (no rotation resource when Lambda ARN is null), mixed rotation (selective rotation on subset of secrets), IAM policy not created by default (create_read_policy=false), IAM policy creation (policy with name pattern `{prefix}-read-secrets`), tag merging (Environment and Team tags merged with Name tag), empty secrets map (no resources created)
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Extensive validation including recovery window range (7-30 days), rotation days range (1-1000 days when specified), policy name prefix format (alphanumeric and +=,.@_-), KMS key ARN format validation
- **Test Focus**: Module logic and conditional resource creation (not simple variable passthrough)
