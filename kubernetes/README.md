# Kubernetes Integration

## What This Is

Kubernetes manifests that enable EKS pods to securely access Aurora PostgreSQL credentials from AWS Secrets Manager using External Secrets Operator and IRSA.

## Files

**Setup (deploy in order)**
- `namespace.yaml` - Application namespace
- `serviceaccount.yaml` - External Secrets SA with IRSA annotation
- `external-secrets-values.yaml` - Helm values for External Secrets Operator
- `secretstore.yaml` - ClusterSecretStore connecting to AWS Secrets Manager

**Secrets Sync**
- `externalsecret-aurora.yaml` - Syncs Aurora credentials to Kubernetes Secrets
- `externalsecret-app.yaml` - Examples for other secret types (API keys, TLS certs)

**Testing & Examples**
- `postgres-client.yaml` - Test pod for Aurora connectivity
- `example-deployment.yaml` - Reference deployment showing secret usage

## Prerequisites

- Terraform infrastructure deployed (creates IAM role and Aurora)
- Helm and kubectl installed

## Deployment

```bash
# Add Helm repo
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Create namespaces
kubectl apply -f namespace.yaml
kubectl create namespace external-secrets

# Create ServiceAccount with IRSA (update ACCOUNT_ID first)
kubectl apply -f serviceaccount.yaml

# Install External Secrets Operator
helm install external-secrets external-secrets/external-secrets \
  -n external-secrets \
  -f external-secrets-values.yaml

# Deploy SecretStore
kubectl apply -f secretstore.yaml

# Sync Aurora credentials
kubectl apply -f externalsecret-aurora.yaml

# Verify
kubectl get externalsecrets -n app
kubectl get secrets -n app
```

## Using Secrets in Apps

**Load all keys as environment variables:**
```yaml
envFrom:
  - secretRef:
      name: aurora-app-credentials
```

**Load specific keys:**
```yaml
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: aurora-app-credentials
        key: DATABASE_URL
```

See `example-deployment.yaml` for complete examples.

## Verification

```bash
# Check operator health
kubectl get pods -n external-secrets

# Check ExternalSecret status
kubectl describe externalsecret aurora-app-credentials -n app

# Test Aurora connection (optional)
kubectl apply -f postgres-client.yaml
kubectl exec -it postgres-client -n app -- psql -c "SELECT version();"
```

## Notes

- Secrets refresh every 5 minutes (configurable via `refreshInterval`)
- IAM role ARN in `serviceaccount.yaml` must match Terraform output
- Use `dataFrom` to extract entire secrets, `data` for specific keys
