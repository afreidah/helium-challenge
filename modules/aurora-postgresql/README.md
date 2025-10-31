# Aurora PostgreSQL Module

## Overview

Creates a production-ready Amazon Aurora PostgreSQL cluster with dedicated compute instances, automated backups, encryption at rest, and comprehensive monitoring. Aurora provides MySQL and PostgreSQL-compatible database built for the cloud with storage that automatically scales from 10GB to 128TB.

## What It Does

- **Aurora Cluster**: Shared storage layer with automated scaling, continuous backup to S3, and point-in-time recovery (PITR)
- **Cluster Instances**: Configurable compute nodes with automatic promotion tiers (1 writer + N readers)
- **DB Subnet Group**: Multi-AZ placement across availability zones for high availability
- **CloudWatch Logs**: PostgreSQL log export for monitoring and troubleshooting

## Key Features

- Automatic failover with Multi-AZ deployment and configurable promotion tiers
- Read replicas for horizontal read scaling with cluster reader endpoint
- Secrets encryption at rest using KMS (dedicated or provided key)
- Performance Insights for query-level performance analysis
- Enhanced monitoring with configurable intervals (1-60 seconds)
- IAM database authentication for password-less access
- Serverless v2 scaling support with configurable ACU limits
- Global Database support for multi-region deployments
- I/O-optimized storage type option (`aurora-iopt1`)
- Automatic minor version upgrades with configurable maintenance windows

## Module Position

This module creates the database layer for your applications:
```
VPC → Subnets → Security Groups → **Aurora PostgreSQL** → Applications
```

## Common Use Cases

- Production databases requiring high availability and automatic failover
- Read-heavy workloads with multiple reader instances
- Multi-region deployments using Global Database
- Applications requiring IAM-based database authentication
- Workloads with variable traffic patterns using Serverless v2
- Compliance requirements needing encrypted storage and audit logs
- Zero-downtime blue/green deployments using fast cloning

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering subnet group naming, single/multi-instance deployments, AZ distribution, failover priorities, Performance Insights, enhanced monitoring, Serverless v2 scaling, final snapshots, and instance inheritance logic
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Extensive input validation for cluster identifiers (lowercase, 1-63 chars), database names, master username (no reserved words), passwords (complexity requirements), instance counts (1-15), version formats, backup retention (1-35 days), window formats, Performance Insights retention periods, monitoring intervals, KMS ARNs, and Serverless v2 ACU ranges
- **Conditional Logic**: KMS key creation when not provided, Performance Insights/monitoring configuration based on flags, Serverless v2 scaling blocks, final snapshot identifier generation
