# Architecture Overview

## Network Design
```
Internet
    ↓
  ALB (public subnets)
    ↓
  EKS Pods (private-app subnets)
    ↓
  Aurora (private-data subnets)
```

## Security Layers
1. WAF → ALB (OWASP Top 10 protection)
2. Security Groups (least privilege)
3. Network ACLs (implicit)
4. KMS encryption at rest
5. Secrets Manager for credentials
