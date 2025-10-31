# Helium - AWS EKS + Aurora PostgreSQL Infrastructure

Production-ready Infrastructure as Code (IaC) for deploying a secure, scalable AWS EKS cluster with Aurora PostgreSQL, implemented using Terragrunt and OpenTofu/Terraform.

## 🎯 Project Overview

This project deploys a complete cloud infrastructure featuring:

- **Amazon EKS 1.31** - Kubernetes cluster with managed node groups
- **Aurora PostgreSQL 15.4** - Multi-AZ database cluster with encryption
- **Application Load Balancer** - With WAF protection and HTTPS support
- **AWS Secrets Manager** - Secure credential management with IRSA
- **External Secrets Operator** - Kubernetes-native secrets synchronization
- **KMS Encryption** - End-to-end encryption for secrets, databases, and logs

## 📋 Table of Contents

- [Architecture](#-architecture)
- [Features](#-features)
- [Prerequisites](#-prerequisites)
- [Quick Start](#-quick-start)
- [Project Structure](#-project-structure)
- [Configuration](#-configuration)
- [Deployment](#-deployment)
- [Post-Deployment](#-post-deployment)
- [CI/CD Pipeline](#-cicd-pipeline)
- [Kubernetes Integration](#-kubernetes-integration)
- [Security](#-security)
- [Cost Estimation](#-cost-estimation)
- [Troubleshooting](#-troubleshooting)
- [Contributing](#-contributing)

## 🏗 Architecture

### Infrastructure Components

```
┌─────────────────────────────────────────────────────────────┐
│                      AWS Cloud                               │
│                                                              │
│  ┌────────────┐         ┌──────────────────┐               │
│  │    WAF     │────────▶│      ALB         │               │
│  └────────────┘         │  (Public Subnet)  │               │
│                         └──────┬───────────┘               │
│                                │                             │
│                                ▼                             │
│                    ┌────────────────────┐                   │
│                    │   EKS Cluster      │                   │
│                    │                    │                   │
│                    │  ┌──────────────┐ │                   │
│                    │  │ Node Group   │ │                   │
│                    │  │ (Private     │ │                   │
│                    │  │  Subnet)     │ │                   │
│                    │  └──────┬───────┘ │                   │
│                    └─────────┼─────────┘                   │
│                              │                              │
│                              ▼                              │
│              ┌──────────────────────────────┐              │
│              │   Aurora PostgreSQL          │              │
│              │   (Private Data Subnet)      │              │
│              │   • Multi-AZ                 │              │
│              │   • KMS Encrypted            │              │
│              │   • Performance Insights     │              │
│              └──────────────────────────────┘              │
│                                                              │
│  ┌────────────────┐        ┌─────────────────┐            │
│  │ Secrets Manager│◀───────│  External       │            │
│  │ • Aurora Creds │  IRSA  │  Secrets        │            │
│  │ • App Secrets  │        │  Operator       │            │
│  └────────────────┘        └─────────────────┘            │
│                                                              │
│  ┌────────────────┐                                        │
│  │      KMS       │  (Encrypts all sensitive data)         │
│  └────────────────┘                                        │
└─────────────────────────────────────────────────────────────┘
```

### Network Architecture

- **VPC CIDR**: 10.0.0.0/16 (production) / 10.1.0.0/16 (staging)
- **Public Subnets**: 10.0.1.0/24, 10.0.2.0/24 (ALB, NAT Gateways)
- **Private App Subnets**: 10.0.16.0/20, 10.0.32.0/20 (EKS nodes)
- **Private Data Subnets**: 10.0.4.0/24, 10.0.5.0/24 (Aurora)
- **Multi-AZ**: us-east-1a, us-east-1b
- **NAT Gateways**: HA setup (2x in prod, 1x in staging)

## ✨ Features

### Infrastructure

- **Modular Design**: Reusable Terraform modules with environment helpers
- **DRY Principles**: Configuration centralized in `root.hcl`
- **Multi-Environment**: Production and staging with environment-specific settings
- **Security Hardening**: 
  - KMS encryption for all data at rest
  - IMDSv2 required on EC2 instances
  - Security groups with least-privilege access
  - WAF with AWS Managed Rules
  - Private subnets for workloads and databases
- **High Availability**:
  - Multi-AZ deployment across 2 availability zones
  - Auto-scaling node groups (2-10 nodes in prod)
  - Aurora read replicas for database scaling
- **Observability**:
  - EKS control plane logging to CloudWatch
  - Aurora Performance Insights
  - CloudWatch metrics for all resources
  - 90-day log retention

### CI/CD

- **Automated Pipeline**: GitHub Actions workflow for plan and apply
- **Security Scanning**: 
  - Trivy for infrastructure vulnerabilities
  - Checkov for policy compliance
  - Gitleaks for secret detection
- **Cost Estimation**: Infracost integration for cost analysis
- **Format Validation**: Automated terraform/terragrunt formatting checks
- **Docker-based CI**: Consistent build environment with all tools

### Kubernetes Integration

- **External Secrets Operator**: Sync AWS Secrets Manager to Kubernetes
- **IRSA Support**: IAM Roles for Service Accounts
- **Ready-to-use Manifests**: Complete example deployments
- **PostgreSQL Client**: Pre-configured test pod for Aurora connectivity

## 📦 Prerequisites

### Required Tools

```bash
# Infrastructure
terraform >= 1.13 or tofu >= 1.10
terragrunt >= 0.91
docker >= 20.10 (for CI toolkit)

# AWS
aws-cli >= 2.0
AWS account with admin permissions
AWS credentials configured

# Optional (for local development)
kubectl >= 1.31
helm >= 3.0
```

### AWS Permissions

The deployment requires an IAM user or role with permissions to create:
- VPC, Subnets, NAT Gateways, Internet Gateways
- EKS Clusters, Node Groups
- RDS Aurora Clusters
- Application Load Balancers
- Security Groups
- KMS Keys
- IAM Roles and Policies
- Secrets Manager Secrets
- CloudWatch Log Groups
- WAF WebACLs

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <your-repo-url>
cd helium
```

### 2. Configure AWS Credentials

```bash
export AWS_ACCESS_KEY_ID="your-access-key"
export AWS_SECRET_ACCESS_KEY="your-secret-key"
export AWS_DEFAULT_REGION="us-east-1"
```

### 3. Review Configuration

Edit `root.hcl` to customize:
- VPC CIDR blocks
- Instance sizes
- Database configuration
- Environment-specific settings

### 4. Initialize Infrastructure

```bash
cd production/us-east-1
terragrunt run-all init
```

### 5. Plan Deployment

```bash
# From repository root
make plan-all

# Or for specific environment
cd production
terragrunt run-all plan
```

### 6. Deploy Infrastructure

```bash
cd production
terragrunt run-all apply
```

**Deployment Order** (handled automatically by dependencies):
1. KMS encryption keys
2. VPC and networking
3. Security groups
4. IAM roles
5. EKS cluster
6. EKS node group
7. Aurora PostgreSQL
8. Secrets Manager
9. ALB and listeners
10. WAF

**Estimated Time**: 25-30 minutes

## 📁 Project Structure

```
.
├── .github/workflows/
│   └── ci.yml                    # GitHub Actions CI/CD pipeline
├── _env_helpers/                 # Reusable Terragrunt configurations
│   ├── README.md                 # Environment helpers documentation
│   ├── general-networking.hcl    # VPC, subnets, NAT gateways
│   ├── security-groups.hcl       # Security group rules
│   ├── iam-role.hcl             # IAM roles (supports IRSA)
│   ├── kms.hcl                  # KMS encryption keys
│   ├── eks-cluster.hcl          # EKS control plane
│   ├── eks-node-group.hcl       # EKS worker nodes
│   ├── aurora-postgresql.hcl    # Aurora database clusters
│   ├── secrets-manager.hcl      # Secrets Manager secrets
│   ├── alb.hcl                  # Application Load Balancer
│   ├── alb-target-groups.hcl    # ALB target groups
│   ├── alb-listeners.hcl        # ALB listeners
│   └── waf.hcl                  # Web Application Firewall
├── kubernetes/                   # Kubernetes manifests
│   ├── README.md                # Kubernetes setup guide
│   ├── namespace.yaml           # Application namespace
│   ├── serviceaccount.yaml      # IRSA service account
│   ├── external-secrets-values.yaml  # Helm values
│   ├── secretstore.yaml         # SecretStore config
│   ├── externalsecret-aurora.yaml    # Aurora credentials sync
│   ├── externalsecret-app.yaml       # App secrets sync
│   ├── postgres-client.yaml     # Test pod
│   └── example-deployment.yaml  # Reference deployment
├── modules/                      # Terraform modules
│   ├── general-networking/      # VPC module
│   ├── security-group/          # Security group module
│   ├── iam-role/                # IAM role module
│   ├── kms/                     # KMS key module
│   ├── eks-cluster/             # EKS cluster module
│   ├── eks-node-group/          # EKS node group module
│   ├── aurora-postgresql/       # Aurora module
│   ├── secrets-manager/         # Secrets Manager module
│   ├── alb/                     # ALB module
│   ├── alb-target-groups/       # Target groups module
│   ├── alb-listeners/           # Listeners module
│   └── waf/                     # WAF module
├── production/                   # Production environment
│   └── us-east-1/               # us-east-1 region
│       ├── general-networking/
│       ├── security-groups-*/
│       ├── iam-role-*/
│       ├── kms/
│       ├── eks-cluster/
│       ├── eks-node-group/
│       ├── aurora-postgresql/
│       ├── secrets-manager/
│       ├── alb/
│       ├── alb-target-groups/
│       ├── alb-listeners/
│       └── waf/
├── staging/                      # Staging environment (optional)
│   └── us-east-1/
├── Dockerfile                    # CI toolkit container
├── Makefile                      # Development automation
├── root.hcl                      # Root Terragrunt configuration
├── README.md                     # This file
└── REQUIREMENTS.md               # Project requirements
```

## ⚙️ Configuration

### Environment Variables

```bash
# Required
export AWS_ACCESS_KEY_ID="your-key"
export AWS_SECRET_ACCESS_KEY="your-secret"
export AWS_DEFAULT_REGION="us-east-1"

# Optional (for Infracost)
export INFRACOST_API_KEY="your-infracost-key"

# Optional (for Aurora password override)
export AURORA_MASTER_PASSWORD="secure-password-here"
```

### Root Configuration (`root.hcl`)

All environment-specific configuration is centralized in `root.hcl`:

```hcl
env_config = {
  production = {
    instance_type = "t3.large"
    replica_count = 3
    vpc_cidr      = "10.0.0.0/16"
    aurora = {
      instance_class          = "db.r6g.xlarge"
      instance_count          = 3
      backup_retention_period = 30
      deletion_protection     = true
    }
  }
  staging = {
    instance_type = "t3.medium"
    replica_count = 2
    vpc_cidr      = "10.1.0.0/16"
    aurora = {
      instance_class          = "db.r6g.large"
      instance_count          = 2
      backup_retention_period = 14
      deletion_protection     = true
    }
  }
}
```

### Key Configuration Sections

- **`networking_config`**: VPC, subnets, NAT gateways
- **`security_group_rules`**: Security group definitions
- **`iam_role_configs`**: IAM roles for EKS and IRSA
- **`alb_config`**: Load balancer settings
- **`aurora_config`**: Database configuration
- **`eks_cluster_config`**: Kubernetes version, add-ons, node groups
- **`secrets_config`**: Secrets Manager secret definitions
- **`waf_config`**: WAF rules and policies

## 🔧 Deployment

### Using Make (Recommended)

```bash
# Format all files
make fmt

# Validate configuration
make validate

# Run tests on modules
make test

# Generate Terraform plans
make plan-all

# Complete CI pipeline (format, validate, test, plan, cost)
make ci

# Clean build artifacts
make clean
```

### Using Terragrunt Directly

```bash
# Initialize single component
cd production/us-east-1/eks-cluster
terragrunt init

# Plan single component
terragrunt plan

# Apply single component
terragrunt apply

# Apply all components in dependency order
cd production/us-east-1
terragrunt run-all apply --terragrunt-parallelism 1
```

### Using Docker CI Toolkit

```bash
# Build CI image
make docker-build

# Run CI in container
make docker-ci

# Or manually
docker build -t helium-ci:latest .
docker run --rm \
  -e AWS_ACCESS_KEY_ID \
  -e AWS_SECRET_ACCESS_KEY \
  -e AWS_DEFAULT_REGION \
  -v $(pwd):/workspace \
  -w /workspace \
  helium-ci:latest \
  bash -c 'make ci'
```

## 🎉 Post-Deployment

### 1. Configure kubectl

```bash
aws eks update-kubeconfig \
  --name production-us-east-1-eks \
  --region us-east-1
```

### 2. Verify Cluster Access

```bash
kubectl cluster-info
kubectl get nodes
kubectl get namespaces
```

### 3. Install External Secrets Operator

```bash
# Add Helm repository
helm repo add external-secrets https://charts.external-secrets.io
helm repo update

# Create namespace
kubectl create namespace external-secrets

# Update ServiceAccount with correct IAM role ARN
# Edit kubernetes/serviceaccount.yaml with your account ID

# Create ServiceAccount
kubectl apply -f kubernetes/serviceaccount.yaml

# Install operator
helm install external-secrets \
  external-secrets/external-secrets \
  -n external-secrets \
  -f kubernetes/external-secrets-values.yaml

# Verify installation
kubectl get pods -n external-secrets
```

### 4. Configure Secrets Synchronization

```bash
# Create application namespace
kubectl apply -f kubernetes/namespace.yaml

# Deploy SecretStore (connects to AWS Secrets Manager)
kubectl apply -f kubernetes/secretstore.yaml

# Deploy ExternalSecrets (syncs Aurora credentials)
kubectl apply -f kubernetes/externalsecret-aurora.yaml

# Verify secret creation
kubectl get externalsecrets -n app
kubectl get secrets -n app
```

### 5. Test Aurora Connectivity

```bash
# Deploy PostgreSQL client pod
kubectl apply -f kubernetes/postgres-client.yaml

# Wait for pod to be ready
kubectl wait --for=condition=ready pod/postgres-client -n app --timeout=60s

# Test connection
kubectl exec -it postgres-client -n app -- psql \
  -h $(kubectl get secret aurora-app-credentials -n app -o jsonpath='{.data.DB_HOST}' | base64 -d) \
  -U $(kubectl get secret aurora-app-credentials -n app -o jsonpath='{.data.DB_USERNAME}' | base64 -d) \
  -d postgres

# Inside psql
SELECT version();
\l  # List databases
\q  # Quit
```

### 6. Retrieve Important Values

```bash
# Get Aurora endpoints
cd production/us-east-1/aurora-postgresql
terragrunt output

# Get EKS cluster details
cd ../eks-cluster
terragrunt output

# Get ALB DNS name
cd ../alb
terragrunt output alb_dns_name
```

### 7. Update Database Passwords

```bash
# After initial deployment, update passwords in Secrets Manager
aws secretsmanager update-secret \
  --secret-id production/aurora/master-credentials \
  --secret-string '{"username":"postgres","password":"NEW_SECURE_PASSWORD","engine":"postgres","port":"5432","dbname":"postgres","host":"<aurora-endpoint>","reader_host":"<reader-endpoint>"}'

aws secretsmanager update-secret \
  --secret-id production/aurora/app-credentials \
  --secret-string '{"username":"appuser","password":"NEW_SECURE_PASSWORD","engine":"postgres","port":"5432","dbname":"postgres","host":"<aurora-endpoint>","reader_host":"<reader-endpoint>"}'
```

## 🔄 CI/CD Pipeline

### GitHub Actions Workflow

The repository includes a complete CI/CD pipeline (`.github/workflows/ci.yml`):

**On Pull Request:**
1. Build Docker CI image
2. Format check (terraform/terragrunt/hcl)
3. Validation (modules and configurations)
4. Terraform tests
5. Generate plans for all environments
6. Run Infracost analysis
7. Comment PR with plan summary and costs

**On Merge to Main:**
1. Same as PR checks
2. Wait for manual approval (production environment)
3. Apply infrastructure changes (CURRENTLY COMMENTED OUT)

### Enabling Auto-Apply

Uncomment the `apply` job in `.github/workflows/ci.yml` and configure:

```bash
# 1. Create GitHub Environment
# Settings → Environments → New environment → "production"

# 2. Add Required Reviewers
# Environment → protection rules → Required reviewers → Add yourself

# 3. Configure Secrets
# Settings → Secrets → Actions:
AWS_ACCESS_KEY_ID
AWS_SECRET_ACCESS_KEY
AWS_DEFAULT_REGION
INFRACOST_API_KEY
```

### Local CI Execution

```bash
# Run complete CI pipeline locally
make ci

# Or in Docker (mimics GitHub Actions)
make docker-ci
```

## ☸️ Kubernetes Integration

### External Secrets Operator

External Secrets Operator synchronizes AWS Secrets Manager secrets into Kubernetes Secrets automatically.

**Architecture:**
```
AWS Secrets Manager → SecretStore (IRSA) → ExternalSecret → Kubernetes Secret
```

**Features:**
- Automatic refresh every 5 minutes
- IRSA authentication (no long-lived credentials)
- Template transformation for connection strings
- Support for JSON secret parsing

### Using Secrets in Deployments

See `kubernetes/example-deployment.yaml` for complete examples:

```yaml
# Option 1: Load all keys as environment variables
envFrom:
  - secretRef:
      name: aurora-app-credentials

# Option 2: Load specific keys
env:
  - name: DATABASE_URL
    valueFrom:
      secretKeyRef:
        name: aurora-app-credentials
        key: DATABASE_URL
```

### Available Secrets

After deployment, these secrets are available in the `app` namespace:

- `aurora-master-credentials` - PostgreSQL admin credentials
- `aurora-app-credentials` - Application database user
- `app-config-secrets` - Application configuration

## 🔒 Security

### Encryption

- **At Rest**: All data encrypted with KMS customer-managed keys
  - Aurora database storage
  - EBS volumes
  - Secrets Manager secrets
  - CloudWatch logs
- **In Transit**: TLS/SSL for all network communication
  - HTTPS on ALB (when configured)
  - Encrypted Aurora connections
  - EKS API server TLS

### Network Security

- **Security Groups**: Least-privilege access rules
  - ALB: HTTP/HTTPS from internet, egress to EKS nodes
  - EKS Nodes: All TCP from VPC (ALB + cluster)
  - Aurora: PostgreSQL (5432) from VPC only
- **Network Isolation**: 
  - Public subnets: ALB and NAT gateways only
  - Private app subnets: EKS nodes (no direct internet)
  - Private data subnets: Aurora (no internet access)
- **WAF**: AWS Managed Rules
  - Common web exploits
  - Known bad inputs
  - IP reputation lists

### IAM and IRSA

- **Principle of Least Privilege**: Minimal permissions per component
- **IRSA**: No long-lived credentials in pods
  - External Secrets Operator assumes IAM role
  - Application pods can assume roles
- **IMDSv2**: Required on all EC2 instances

### Compliance Scanning

Built-in security scanning with Checkov and Trivy:

```bash
# Run security scans
make ci

# Or manually
checkov -d . --quiet
trivy config .
```

## 💰 Cost Estimation

### Using Infracost

```bash
# Generate cost estimates
export INFRACOST_API_KEY="your-key"
make cost

# View estimates
cat .ci/plan/cost-production.txt
cat .ci/plan/cost-staging.txt
```

### Estimated Monthly Costs (Production)

| Component | Configuration | Estimated Cost |
|-----------|--------------|----------------|
| EKS Cluster | Control Plane | $72/month |
| EKS Nodes | 3x t3.large | ~$190/month |
| Aurora PostgreSQL | 3x db.r6g.xlarge | ~$1,460/month |
| ALB | Application Load Balancer | ~$23/month |
| NAT Gateway | 2x Multi-AZ | ~$70/month |
| KMS | 1 key | $1/month |
| Secrets Manager | 3 secrets | $1.20/month |
| **Total** | | **~$1,817/month** |

*Note: Costs vary based on usage, data transfer, and region. Use Infracost for accurate estimates.*

### Cost Optimization Tips

- **Staging**: Uses smaller instances (t3.medium, db.r6g.large)
- **Single NAT**: Staging uses one NAT gateway vs. two in production
- **Reserved Instances**: Save 30-40% with 1-year commitments
- **Spot Instances**: Consider for non-critical workloads
- **Auto-scaling**: Nodes scale down during low usage

## 🐛 Troubleshooting

### Terragrunt Issues

**Error: "Dependency not found"**
```bash
# Ensure components are deployed in order
cd production/us-east-1
terragrunt run-all init
terragrunt run-all apply --terragrunt-parallelism 1
```

**Error: "Backend initialization required"**
```bash
# Re-initialize
cd production/us-east-1/<component>
rm -rf .terraform .terraform.lock.hcl
terragrunt init
```

### EKS Issues

**Cannot connect to cluster**
```bash
# Update kubeconfig
aws eks update-kubeconfig --name production-us-east-1-eks --region us-east-1

# Verify AWS credentials
aws sts get-caller-identity

# Check cluster status
aws eks describe-cluster --name production-us-east-1-eks
```

**Nodes not joining cluster**
```bash
# Check node group status
kubectl get nodes
aws eks describe-nodegroup \
  --cluster-name production-us-east-1-eks \
  --nodegroup-name production-us-east-1-eks-nodes

# Check node IAM role
aws iam get-role --role-name production-us-east-1-eks-node
```

### Aurora Issues

**Cannot connect from EKS**
```bash
# Verify security group rules
aws ec2 describe-security-groups \
  --filters "Name=tag:Component,Values=security-groups-aurora"

# Test from PostgreSQL client pod
kubectl exec -it postgres-client -n app -- ping <aurora-endpoint>
kubectl exec -it postgres-client -n app -- nc -zv <aurora-endpoint> 5432
```

### External Secrets Issues

**ExternalSecret not syncing**
```bash
# Check operator logs
kubectl logs -n external-secrets -l app.kubernetes.io/name=external-secrets

# Check ExternalSecret status
kubectl describe externalsecret aurora-app-credentials -n app

# Verify IRSA configuration
kubectl describe sa external-secrets-sa -n external-secrets
```

**IAM permissions issue**
```bash
# Test IAM role
aws sts assume-role-with-web-identity \
  --role-arn <role-arn> \
  --role-session-name test \
  --web-identity-token $(cat /var/run/secrets/eks.amazonaws.com/serviceaccount/token)
```

### General Debugging

```bash
# Enable verbose logging
export TF_LOG=DEBUG
export TERRAGRUNT_LOG_LEVEL=debug

# Clean and retry
make clean
cd production/us-east-1
terragrunt run-all init
```

## 📚 Documentation

- [Environment Helpers](_env_helpers/README.md) - Reusable Terragrunt configurations
- [Kubernetes Integration](kubernetes/README.md) - External Secrets setup
- [Project Requirements](REQUIREMENTS.md) - Original challenge requirements
- [CI/CD Workflow](.github/workflows/ci.yml) - Pipeline documentation

### Code Standards

- **Format**: Use `terraform fmt` and `hclfmt`
- **Validation**: All modules must pass `terraform validate`
- **Testing**: Include terraform tests in modules
- **Documentation**: Update README.md for significant changes
- **Security**: Run Checkov and Trivy scans

### Adding New Components

1. Create module in `modules/`
2. Create environment helper in `_env_helpers/`
3. Add configuration to `root.hcl`
4. Create environment-specific files in `production/`
5. Update documentation
