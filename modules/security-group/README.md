# Security Group Module

## Overview

Creates AWS VPC security groups with configurable ingress and egress rules for network traffic control. Rules are created as separate resources (not inline) to enable granular management and avoid update limitations. The module uses create-before-destroy lifecycle to ensure safe updates during rule modifications without connectivity disruption.

## What It Does

- **Security Group**: VPC security group for network access control with environment and component-based naming
- **Ingress Rules**: Inbound traffic rules created as separate `aws_vpc_security_group_ingress_rule` resources
- **Egress Rules**: Outbound traffic rules created as separate `aws_vpc_security_group_egress_rule` resources
- **Name Construction**: Automatic naming from environment and name_suffix (`{environment}-{name_suffix}`)

## Key Features

- Separate rule resources for granular management (no inline rule limitations)
- Create-before-destroy lifecycle prevents connectivity disruption during updates
- CIDR block sources with validation
- Multiple protocols supported (TCP, UDP, ICMP, ALL/-1)
- Configurable port ranges (0-65535)
- Rule descriptions for documentation and audit trails
- Empty rule lists supported (database pattern: ingress only, no egress)
- Comprehensive input validation (VPC ID, environment, region, ports, protocols, CIDR blocks)
- Integration with root.hcl security group rule definitions
- Security scanner suppressions for common patterns (public ALB, EC2 internet access)

## Module Position

This module provides network security layer between VPC subnets and AWS resources:
```
VPC → Subnets → **Security Groups** → EC2/EKS/RDS/ALB
```

## Common Use Cases

- Application Load Balancer security groups (public HTTP/HTTPS ingress)
- Aurora PostgreSQL database security groups (VPC ingress only, no egress)
- EKS node security groups (VPC ingress, internet egress)
- Lambda function security groups (egress-only for outbound connections)
- Private application security groups (bastion SSH ingress, limited egress)
- Multi-tier architectures with layered security groups

## Testing & Validation

- **Terraform Tests**: Comprehensive test suite covering name prefix interpolation (environment + name_suffix construction), tag merging with Name tag generation, multiple ingress rules (3 rules with different ports and CIDRs), empty egress rules for database pattern (ingress only, no egress), empty ingress rules for egress-only pattern (Lambda outbound), completely empty rule sets (placeholder security groups), VPC association validation
- **Run Tests**: `terraform test` from the module directory
- **Variable Validation**: Extensive validation including VPC ID format (vpc-xxxxxxxx), environment values (production/staging/development/prod/stage/dev), region format (us-east-1), name_suffix length (1-50 chars), description length (1-255 chars), port numbers (0-65535 with from_port ≤ to_port), protocol values (tcp/udp/icmp/icmpv6/all/-1), CIDR block validity, tag key/value lengths
- **Security Scanner Skips**: tfsec aws-ec2-no-public-ingress-sgr and Checkov CKV_AWS_260 for public ALB (intentional internet access on 80/443), tfsec aws-ec2-no-public-egress-sgr, Checkov CKV_AWS_23, and Trivy AVD-AWS-0104 for EC2/EKS egress (required for package updates and AWS API access)

### Application Load Balancer Security Group

```hcl
module "alb_sg" {
  source = "./modules/security-group"

  vpc_id      = module.vpc.vpc_id
  environment = "production"
  region      = "us-east-1"

  security_group_rules = {
    name_suffix = "alb"
    description = "Security group for Application Load Balancer"
    
    ingress_rules = [
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP from internet"
      },
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS from internet"
      }
    ]
    
    egress_rules = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }

  tags = {
    Environment = "production"
    Service     = "alb"
  }
}
```

### Aurora PostgreSQL Security Group

```hcl
module "aurora_sg" {
  source = "./modules/security-group"

  vpc_id      = module.vpc.vpc_id
  environment = "production"
  region      = "us-east-1"

  security_group_rules = {
    name_suffix = "aurora-postgresql"
    description = "Security group for Aurora PostgreSQL cluster"
    
    ingress_rules = [
      {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]  # VPC CIDR
        description = "PostgreSQL from VPC"
      }
    ]
    
    egress_rules = []  # No egress for database
  }

  tags = {
    Environment = "production"
    Service     = "aurora"
  }
}
```

### EKS Node Security Group

```hcl
module "eks_node_sg" {
  source = "./modules/security-group"

  vpc_id      = module.vpc.vpc_id
  environment = "production"
  region      = "us-east-1"

  security_group_rules = {
    name_suffix = "eks-nodes"
    description = "Security group for EKS worker nodes"
    
    ingress_rules = [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "HTTPS from VPC"
      },
      {
        from_port   = 1025
        to_port     = 65535
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "NodePort services from VPC"
      }
    ]
    
    egress_rules = [
      {
        from_port   = 0
        to_port     = 0
        protocol    = "-1"
        cidr_blocks = ["0.0.0.0/0"]
        description = "All outbound traffic"
      }
    ]
  }

  tags = {
    Environment = "production"
    Service     = "eks"
  }
}
```

### Lambda Function Security Group (Egress Only)

```hcl
module "lambda_sg" {
  source = "./modules/security-group"

  vpc_id      = module.vpc.vpc_id
  environment = "production"
  region      = "us-east-1"

  security_group_rules = {
    name_suffix = "lambda-egress"
    description = "Security group for Lambda functions"
    
    ingress_rules = []  # No ingress needed
    
    egress_rules = [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS to internet"
      },
      {
        from_port   = 5432
        to_port     = 5432
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "PostgreSQL to RDS"
      }
    ]
  }

  tags = {
    Environment = "production"
    Service     = "lambda"
  }
}
```

### Private Subnet Resources Security Group

```hcl
module "private_sg" {
  source = "./modules/security-group"

  vpc_id      = module.vpc.vpc_id
  environment = "production"
  region      = "us-east-1"

  security_group_rules = {
    name_suffix = "private-resources"
    description = "Security group for private subnet resources"
    
    ingress_rules = [
      {
        from_port   = 22
        to_port     = 22
        protocol    = "tcp"
        cidr_blocks = ["10.0.1.0/24"]  # Bastion subnet
        description = "SSH from bastion"
      },
      {
        from_port   = 8080
        to_port     = 8080
        protocol    = "tcp"
        cidr_blocks = ["10.0.0.0/16"]
        description = "Application port from VPC"
      }
    ]
    
    egress_rules = [
      {
        from_port   = 443
        to_port     = 443
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTPS to internet"
      },
      {
        from_port   = 80
        to_port     = 80
        protocol    = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
        description = "HTTP to internet"
      }
    ]
  }

  tags = {
    Environment = "production"
    Service     = "app"
  }
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| vpc_id | ID of the VPC where security group will be created | `string` | n/a | yes |
| environment | Environment name (production, staging, development, prod, stage, dev) | `string` | n/a | yes |
| region | AWS region where resources will be created | `string` | n/a | yes |
| security_group_rules | Security group rule configuration containing name, description, and rules | `object` | n/a | yes |
| tags | A map of tags to add to all resources | `map(string)` | `{}` | no |

### Security Group Rules Object

```hcl
{
  name_suffix = string         # Suffix appended to environment for SG name
  description = string         # Security group description
  ingress_rules = list(object({
    from_port   = number       # Start of port range (0-65535)
    to_port     = number       # End of port range (0-65535)
    protocol    = string       # tcp, udp, icmp, icmpv6, all, -1
    cidr_blocks = list(string) # List of CIDR blocks
    description = string       # Rule description
  }))
  egress_rules = list(object({
    from_port   = number
    to_port     = number
    protocol    = string
    cidr_blocks = list(string)
    description = string
  }))
}
```

## Outputs

| Name | Description |
|------|-------------|
| security_group_id | ID of the security group |
| security_group_arn | ARN of the security group |
| security_group_name | Name of the security group |

## Common Port Reference

| Service | Port | Protocol | Description |
|---------|------|----------|-------------|
| HTTP | 80 | TCP | Web traffic |
| HTTPS | 443 | TCP | Secure web traffic |
| SSH | 22 | TCP | Secure shell |
| RDP | 3389 | TCP | Remote desktop |
| PostgreSQL | 5432 | TCP | PostgreSQL database |
| MySQL/Aurora | 3306 | TCP | MySQL/Aurora database |
| Redis | 6379 | TCP | Redis cache |
| Kafka | 9092 | TCP | Kafka broker |
| Elasticsearch | 9200 | TCP | Elasticsearch HTTP |
| All traffic | 0 | -1 | All protocols and ports |

## Important Notes

- **Name Prefix**: Security group name is automatically constructed as `{environment}-{name_suffix}`
- **Lifecycle**: Security groups use `create_before_destroy` to prevent connectivity disruption during updates
- **Separate Resources**: Rules are created as separate resources (`aws_vpc_security_group_ingress_rule`, `aws_vpc_security_group_egress_rule`)
- **Empty Rules**: Both `ingress_rules` and `egress_rules` can be empty lists
- **CIDR Format**: CIDR blocks must be valid (e.g., `0.0.0.0/0`, `10.0.0.0/16`)
- **Protocol Values**: Use `tcp`, `udp`, `icmp`, `icmpv6`, `all`, or `-1`
- **Port Ranges**: `from_port` must be less than or equal to `to_port`
- **Regional Resource**: Security groups are VPC-specific and regional

## Security Best Practices

1. **Principle of Least Privilege**: Only allow necessary ports and protocols
2. **Restrict CIDR Blocks**: Use specific CIDR ranges instead of `0.0.0.0/0` when possible
3. **Document Rules**: Provide clear descriptions for each rule
4. **Separate Security Groups**: Create separate security groups for different tiers (web, app, database)
5. **No Egress for Databases**: Database security groups typically should not have egress rules
6. **Use Security Group References**: Reference other security groups instead of CIDR blocks when possible (requires manual configuration)
7. **Regular Audits**: Periodically review and remove unused rules

## Security Scanner Suppressions

The module includes suppressions for common security scanner warnings:

- **Public Ingress (Checkov CKV_AWS_260, tfsec aws-ec2-no-public-ingress-sgr)**: Suppressed for ALB security groups that require internet access on ports 80/443
- **Public Egress (Checkov CKV_AWS_23, tfsec aws-ec2-no-public-egress-sgr, Trivy AVD-AWS-0104)**: Suppressed for EC2/EKS instances that need internet access for package updates and AWS APIs

Review and adjust these suppressions based on your specific security requirements and organizational policies.

## Validation Rules

The module includes comprehensive input validation:

- VPC ID must be valid format (`vpc-xxxxxxxx`)
- Environment must be one of: `production`, `staging`, `development`, `prod`, `stage`, `dev`
- Region must be valid AWS region format (e.g., `us-east-1`)
- Name suffix must be 1-50 characters
- Description must be 1-255 characters
- Port numbers must be 0-65535
- `from_port` must be ≤ `to_port`
- Protocol must be valid (`tcp`, `udp`, `icmp`, `icmpv6`, `all`, `-1`)
- CIDR blocks must be valid CIDR notation
- Tag keys must be ≤ 128 characters
- Tag values must be ≤ 256 characters
