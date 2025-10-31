# General Networking (VPC) Module

## Overview

Creates a production-ready AWS Virtual Private Cloud with a three-tier subnet architecture (public, private application, private data) distributed across multiple availability zones for high availability and fault isolation. Implements network segmentation best practices with dedicated NAT Gateways per AZ for the application tier.

## What It Does

- **VPC**: Virtual network with DNS support enabled for Route53 integration
- **Internet Gateway**: Public internet connectivity for public subnets
- **Public Subnets**: Hosts NAT gateways, load balancers, and bastion hosts (one per AZ)
- **Private App Subnets**: Application tier with dedicated per-AZ NAT Gateways for fault isolation (one per AZ)
- **Private Data Subnets**: Database tier with shared route table using single NAT Gateway for cost optimization (one per AZ)
- **NAT Gateways**: Outbound internet access with Elastic IPs (one per AZ by default)
- **Route Tables**: Public route table with IGW default route, per-AZ app route tables with per-AZ NAT, shared data route table with single NAT

## Key Features

- Three-tier network segmentation (public, private-app, private-data)
- Multi-AZ deployment with configurable availability zones (default: 3 AZs)
- Per-AZ NAT Gateways for application tier (isolated failure domains)
- Shared NAT Gateway for data tier (cost optimization)
- Public subnets with `map_public_ip_on_launch` for NAT and ALB
- DNS resolution and DNS hostnames enabled
- Automatic tagging with tier labels (public, private-app, private-data)
- Configurable CIDR blocks for all subnet tiers
- Internet Gateway for public internet access
- Elastic IPs for static NAT Gateway addressing

## Module Position

This module provides the foundational network layer for all AWS resources:
```
**VPC** → Subnets → Security Groups → Applications/Databases
```

## Common Use Cases

- Multi-tier web applications with public ALBs and private backends
- EKS cluster deployments with private node subnets
- RDS databases in isolated data tier subnets
- Cost-optimized data tier with minimal internet access
- High-availability applications with per-AZ NAT isolation
- Microservices architectures with network segmentation
- Compliance requirements needing private-by-default networking
- Blue/green deployments with separate VPCs

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering baseline 3-AZ deployment (VPC DNS settings, IGW creation, subnet counts per tier, public IP auto-assignment, per-AZ NAT Gateways and EIPs, route table creation and associations, default routes), tagging and naming conventions (tier tags, Name tags, vpc_name prefixing), outputs validation (subnet ID lists, NAT Gateway IDs, route table IDs, AZ passthrough), NAT Gateway disabled scenario (empty NAT IDs), and routing specifics (IGW routes, per-AZ NAT routes for app tier, shared NAT route for data tier)
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Basic type validation for strings, lists, and booleans (allows flexibility for any valid CIDR blocks)
- **Architectural Decisions**: Per-AZ NAT for app tier provides fault isolation (AZ failure doesn't affect other AZs), shared NAT for data tier minimizes cost (databases rarely need internet), public subnets enable map_public_ip_on_launch for NAT/ALB requirements
- **Cost Considerations**: NAT Gateways incur hourly charges and data transfer costs (default: 3 NAT Gateways), option to use single NAT Gateway across all AZs via `single_nat_gateway` flag (not recommended for production)
