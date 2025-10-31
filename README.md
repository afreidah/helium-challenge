# Architecture Challenge - AWS EKS + Aurora PostgreSQL

## Architecture
- EKS 1.31 cluster with managed node groups
- Aurora PostgreSQL 15.4 with Multi-AZ
- Application Load Balancer with WAF
- Secrets Manager for credential management

## Prerequisites
- AWS CLI configured
- Terraform/OpenTofu 1.13+
- Terragrunt 0.91+
- Docker (for CI toolkit)

## Deployment
1. Set credentials: `export AWS_ACCESS_KEY_ID=... AWS_SECRET_ACCESS_KEY=...`
2. Initialize: `cd production && terragrunt run-all init`
3. Plan: `make plan-all`
4. Apply: `cd production && terragrunt run-all apply`

## Post-Deployment
1. Configure kubectl: `aws eks update-kubeconfig --name production-us-east-1-eks`
2. Deploy PostgreSQL client: `kubectl apply -f kubernetes/`
3. Test connection: `kubectl exec -it postgres-client -- psql`
