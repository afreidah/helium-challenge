# EKS Cluster Module

## Overview

Creates a production-ready Amazon Elastic Kubernetes Service (EKS) cluster with comprehensive security hardening, encryption, control plane logging, and IAM integration. Provides a fully managed Kubernetes control plane with automated add-on management and flexible authentication options.

## What It Does

- **EKS Cluster**: Managed Kubernetes control plane with configurable API endpoint access (public/private)
- **IAM Roles**: Cluster service role and VPC CNI service account role with IRSA support
- **Security Groups**: Network access control for control plane communication
- **CloudWatch Logs**: Control plane audit and diagnostic logging (api, audit, authenticator, controllerManager, scheduler)
- **OIDC Provider**: IAM Roles for Service Accounts (IRSA) integration for pod-level IAM permissions
- **EKS Add-ons**: Managed VPC CNI, CoreDNS, kube-proxy, and Pod Identity Agent with version control
- **AWS Auth ConfigMap**: Optional IAM-to-Kubernetes RBAC mapping
- **KMS Encryption**: Dedicated or provided KMS key for Kubernetes secrets encryption

## Key Features

- Secrets encryption at rest using KMS with automatic key rotation
- Control plane logging to CloudWatch with configurable retention
- Private and/or public API endpoint access with CIDR restrictions
- OIDC provider for IRSA (pod-level IAM without node credentials)
- Pod Identity Agent for simplified IAM integration (recommended over IRSA)
- Automated add-on management (VPC CNI with IRSA, CoreDNS, kube-proxy)
- Flexible authentication modes: `API_AND_CONFIG_MAP` (default) or `API` (IAM-only)
- Cluster creator admin permissions (configurable bootstrap)
- IMDSv2 enforcement for enhanced metadata security
- Multi-subnet deployment for high availability

## Module Position

This module creates the Kubernetes control plane for your containerized applications:
```
VPC → Subnets → Security Groups → **EKS Cluster** → Node Groups → Pods
```

## Common Use Cases

- Production Kubernetes clusters with security hardening
- Microservices architectures requiring pod-level IAM permissions via IRSA or Pod Identity
- Private clusters with VPN/Direct Connect access
- Multi-tenant clusters with IAM-based access control
- Compliance-required deployments needing audit logging and encryption
- GitOps workflows requiring cluster creator admin access
- Organizations standardizing on EKS managed add-ons

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering security defaults (encryption, KMS rotation, IMDSv2), CloudWatch log group naming, control plane logging, endpoint configurations (private-only, public with CIDR restrictions), OIDC provider creation, add-on installation (VPC CNI with IRSA, CoreDNS, kube-proxy), security groups, IAM role policies, CloudWatch retention, and multi-subnet HA deployment
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Extensive input validation for cluster names (1-100 chars, alphanumeric+hyphens), VPC IDs, subnet IDs (minimum 2 for HA), KMS key ARNs, Kubernetes versions (1.28+), public access CIDRs, log types, CloudWatch retention periods, add-on versions (vX.Y.Z-eksbuild.N format), authentication modes, IAM role/user ARNs, node group defaults (IMDSv2 required, disk encryption enforced, sizing constraints), and tag limits
- **Conditional Logic**: KMS key creation when not provided, security group rules based on node SG presence, add-on installation based on flags, aws-auth ConfigMap management based on authentication mode, conditional logging based on flags
- **Security Enforcement**: IMDSv2 required, disk encryption enforced, private access required when public disabled, maximum CIDR blocks enforced
