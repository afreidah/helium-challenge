# Kubernetes → Aurora PostgreSQL Integration

## How It Works

1. **AWS Secrets Manager** stores Aurora credentials (managed by Terraform)
2. **External Secrets Operator** syncs secrets to Kubernetes
3. **PostgreSQL client pod** reads secrets and connects to Aurora

## Network Path
```
EKS Pod (10.0.16.0/20)
    ↓ Security Group: eks-nodes (allow all egress)
    ↓ Route Table: NAT Gateway → VPC
    ↓ Security Group: aurora (allow 5432 from VPC CIDR)
Aurora Endpoint (10.0.4.0/24)
```

## Proof Points

### 1. Security Group Rules Allow Traffic
From `root.hcl`:
- EKS nodes: Allow all egress to 0.0.0.0/0
- Aurora: Allow ingress from 10.0.0.0/16 on port 5432

### 2. Secrets Available in AWS
```bash
aws secretsmanager get-secret-value \
  --secret-id production/aurora/app-credentials \
  --query SecretString --output text | jq .
```

### 3. Kubernetes Can Assume IAM Role
```bash
# External Secrets SA can read secrets
kubectl describe sa external-secrets -n external-secrets
# Annotations: eks.amazonaws.com/role-arn: arn:aws:iam::...
```

### 4. Connection Test (If Deployed)
```bash
kubectl exec -it postgres-client -- \
  psql -h $PGHOST -U $PGUSER -d postgres -c "SELECT version();"
```
