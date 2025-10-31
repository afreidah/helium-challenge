# ALB Target Groups Module

## Overview

Creates and configures ALB target groups that serve as backend pools for routing traffic to application instances or IP addresses. Target groups are independent of the ALB and contain health check and routing configuration for specific backend services.

## What It Does

- **Target Groups**: Backend pools with independent configuration for different services or applications
- **Health Checks**: Per-target-group health monitoring with configurable thresholds and intervals
- **Session Stickiness**: Optional cookie-based session affinity for stateful applications
- **Graceful Shutdown**: Deregistration delay allows in-flight requests to complete before removing targets

## Key Features

- Support for multiple target types: `instance` (EC2), `ip` (EKS pods with AWS VPC CNI), `lambda`, `alb`
- Independent health check configuration per target group
- Automatic name truncation to meet 32-character AWS limit
- Configurable deregistration delays for zero-downtime deployments
- Session persistence with customizable cookie duration
- `create_before_destroy` lifecycle for safe updates

## Module Position

This module creates target groups that bridge the ALB and your applications:
```
VPC → ALB → **Target Groups** → EKS Nodes → Target Registration → Listeners
```

## Common Use Cases

- Creating separate target groups for frontend and backend services
- EKS pod routing using `ip` target type with AWS VPC CNI
- Session-based applications requiring sticky sessions
- Blue/green deployments with multiple target groups
- Microservices with different health check requirements
- Progressive traffic shifting between target groups

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering instance/IP target types, health checks, session stickiness, multiple target groups, and name truncation
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Type-safe configuration with optional stickiness attribute for flexible target group definitions
- **Name Handling**: Automatic truncation and validation to ensure compliance with AWS 32-character limit
