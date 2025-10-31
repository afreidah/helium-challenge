# WAF Module

## Overview

Creates AWS WAFv2 WebACL with configurable managed rule groups, rate limiting, geographic blocking, and comprehensive logging for application protection against common web exploits and attacks. The WebACL can be scoped for regional resources (ALB/API Gateway) or global CloudFront distributions with flexible rule configuration and observability.

## What It Does

- **WAF WebACL**: AWS WAFv2 Web Application Firewall with configurable default action (allow or block)
- **AWS Managed Rules**: Protection against OWASP Top 10 threats, known bad inputs, and malicious IP addresses
- **Rate Limiting**: Request throttling per source IP address to prevent abuse and flooding
- **Geographic Blocking**: Country-based traffic filtering using ISO 3166-1 alpha-2 codes
- **CloudWatch Logging**: Full request logging with sensitive field redaction (authorization, cookie headers)
- **Visibility Configuration**: CloudWatch metrics and sampled request logging for all rules and the WebACL

## Key Features

- AWS managed rule groups (Core Rule Set, Known Bad Inputs, IP Reputation List)
- IP reputation lists to block known malicious sources automatically
- Rate limiting with configurable threshold (100-20M requests per 5 minutes)
- Geographic blocking supporting up to 250 country codes
- Regional (ALB/API Gateway) or CloudFront scope support
- CloudWatch logging with configurable retention (0-3653 days) and KMS encryption
- Sensitive field redaction from logs (authorization and cookie headers by default)
- CloudWatch metrics and sampled requests for monitoring and troubleshooting
- Configurable default action (allow or block)
- Dynamic rule creation using conditional logic (enable/disable individual protections)
- Priority-based rule evaluation (managed rules at priority 10-30, rate limit at 40, geo-blocking at 50)

## Module Position

This module provides application-layer protection for public-facing resources:
```
Internet → **WAF WebACL** → ALB/CloudFront → Application
```

## Common Use Cases

- Application Load Balancer protection against OWASP Top 10 vulnerabilities
- CloudFront distribution security with global threat intelligence
- Rate limiting to prevent DDoS attacks and API abuse
- Geographic access restrictions for compliance requirements
- Bot protection using IP reputation lists
- Security logging for compliance and incident investigation

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering baseline defaults (all managed rules enabled, rate limiting at 2000 requests, CloudWatch metrics and sampling enabled), default action block configuration, selective managed rules (disable core rules while keeping IP reputation), disable reputation and rate limiting for minimal protection, geographic blocking with multiple country codes (RU, CN validation), CloudFront scope for global distribution protection, metrics and sampling disabled for minimal observability
- **Run Tests**: `terraform test` from the module directory  
- **Variable Validation**: Extensive validation including WAF name format (alphanumeric, hyphens, underscores only) and length (1-128 chars), scope values (REGIONAL or CLOUDFRONT only), default action (allow or block), rate limit range (100-20M requests per 5 minutes), country codes (ISO 3166-1 alpha-2 format, max 250 countries), log retention days (valid CloudWatch retention periods), KMS key ARN format, redacted field names (alphanumeric, hyphens, underscores only, max 100 fields)
- **Plan-Safe Assertions**: Tests avoid equality checks against computed values (capacity, IDs, ARNs) that are unknown at plan time, focusing on rule presence, visibility settings, and tag propagation
