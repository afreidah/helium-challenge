# Deployment Guide

## Order of Operations
1. KMS → General Networking → Security Groups
2. IAM Roles → EKS Cluster
3. EKS Node Group
4. Aurora PostgreSQL → Secrets Manager
5. ALB → Target Groups → Listeners → WAF

## Troubleshooting
- **EKS nodes not joining**: Check IAM role attached to node group
- **Aurora connection timeout**: Verify security group rules
- **ALB health checks failing**: Ensure target group port matches pod
