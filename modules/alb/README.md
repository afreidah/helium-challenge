# ALB Listeners Module

## Overview

Creates and manages Application Load Balancer listeners and routing rules. This module handles traffic routing from the ALB to target groups through HTTP/HTTPS listeners and supports advanced routing patterns.

## What It Does

- **HTTP Listener (Port 80)**: Handles unencrypted traffic with configurable actions (redirect to HTTPS, forward to target group, or return fixed response)
- **HTTPS Listener (Port 443)**: Handles encrypted traffic with SSL/TLS termination using ACM certificates
- **Listener Rules**: Implements path-based and host-based routing for microservices and multi-tenant architectures

## Key Features

- Automatic HTTP to HTTPS redirect when certificates are provided
- Modern TLS 1.3 security policy support
- Multiple action types: forward, redirect, fixed-response
- Priority-based rule evaluation for complex routing scenarios
- Support for maintenance pages via fixed-response actions

## Module Position

This module sits between the ALB module and target groups in the dependency chain:
```
VPC → ALB → Target Groups → **Listeners** → Application
```

## Common Use Cases

- Redirecting all HTTP traffic to HTTPS for security
- Routing `/api/*` paths to backend API target groups
- Host-based routing for multi-tenant applications (app1.example.com vs app2.example.com)
- Serving maintenance pages during deployments

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering HTTP/HTTPS listeners, redirect actions, forward actions, fixed responses, path-based routing, and host-based routing
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Type-safe configuration with optional attributes for flexible listener and rule definitions
