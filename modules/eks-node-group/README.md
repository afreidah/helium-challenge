# EKS Node Group Module

## Overview

Creates EKS Managed Node Groups with Launch Templates to provide self-healing worker nodes for Kubernetes workloads. Implements security best practices including IMDSv2 enforcement, EBS encryption, and minimal IAM permissions with optional SSM access for secure shell access without SSH keys.

## What It Does

- **EKS Managed Node Group**: Auto-scaling worker nodes with automated health checks and self-healing
- **Launch Template**: Node configuration with IMDSv2 enforcement, encrypted EBS volumes, and user-data bootstrap script
- **IAM Role & Instance Profile**: Minimal permissions for nodes to join cluster, pull images, and optionally access SSM/CloudWatch
- **Security Group**: Network access control for pod-to-pod communication and cluster API access
- **EKS-Optimized AMI**: Automatically retrieves latest AMI via SSM Parameter Store (or use custom AMI)

## Key Features

- IMDSv2 enforcement with hop limit 2 for pod metadata access
- EBS volume encryption with optional KMS key
- Automatic AMI selection via SSM Parameter Store
- Optional SSM Session Manager for secure shell access (no SSH keys)
- Optional CloudWatch detailed monitoring (1-minute intervals)
- Kubernetes labels and taints for workload scheduling
- Rolling updates with configurable max unavailable percentage
- Per-AZ security group rules for cluster and internet communication
- ON_DEMAND or SPOT capacity types
- Launch template uses name_prefix for blue-green deployments
- Node group ignores `desired_size` changes to prevent drift

## Module Position

This module creates the compute layer for your Kubernetes cluster:
```
VPC → Subnets → EKS Cluster → **Node Groups** → Pods
```

## Common Use Cases

- Production EKS worker nodes with security hardening
- Spot instance node groups for cost optimization
- GPU workloads with taints (e.g., `dedicated=gpu:NoSchedule`)
- Node groups with specific instance types per workload
- SSM-enabled nodes for secure troubleshooting without SSH
- Multi-AZ node distribution for high availability
- Custom AMI deployments for specialized workloads
- Node groups with CloudWatch monitoring for cost analysis

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering security defaults (IMDSv2 required, hop limit 2, EBS encryption, delete on termination), IAM policies (Worker, CNI, ECR, conditional SSM/CloudWatch), security group rules (node-to-node, cluster ingress/egress, internet egress for HTTPS/HTTP/DNS/NTP), launch template versioning with name_prefix, naming conventions, custom KMS encryption, multi-subnet HA deployment, scaling configuration, tag propagation to instances/volumes, Kubernetes taints/labels (AWS format validation), and instance metadata tags
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Basic type validation for strings, numbers, and lists (minimal validation to allow flexibility)
- **Conditional Logic**: SSM policy attachment based on `enable_ssm_access` flag, CloudWatch policy based on `enable_cloudwatch_agent` flag, custom AMI vs SSM Parameter Store lookup, instance profile conditional creation
- **Bootstrap Script**: User-data template joins nodes to cluster with configurable extra arguments
