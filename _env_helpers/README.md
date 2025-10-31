# Environment Helpers

## What Are They?

Environment helpers are reusable Terragrunt configuration templates that eliminate duplication across environments. Instead of repeating 200 lines of configuration logic in every environment, each environment file becomes 5-10 lines that simply includes the helper.

Each helper defines:
- Terraform module source path
- Dependencies with mock outputs for planning
- Configuration mapping from `root.hcl` to module inputs

## Standard Pattern

```hcl
terraform {
  source = "${get_repo_root()}/modules/<component>"
}

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

dependency "example" {
  config_path  = "../example"
  mock_outputs = { example_output = "mock-value" }
}

inputs = {
  config_value     = local.root.inputs.example_config.value
  dependency_value = dependency.example.outputs.example_output
}
```

## Usage

```hcl
# production/us-east-1/eks-cluster/terragrunt.hcl

include "root" {
  path   = find_in_parent_folders("root.hcl")
  expose = true
}

include "eks_cluster" {
  path = "${get_repo_root()}/_env_helpers/eks-cluster.hcl"
}
```

That's it. All configuration comes from `root.hcl` via the helper. Add a local `inputs` block only when you need environment-specific overrides.

## Available Helpers

- `general-networking.hcl` - VPC, subnets, NAT gateways
- `security-groups.hcl` - Security groups with rules
- `eks-cluster.hcl` - EKS control plane
- `eks-node-group.hcl` - EKS worker nodes
- `alb.hcl` - Application Load Balancer
- `alb-target-groups.hcl` - ALB target groups
- `alb-listeners.hcl` - ALB listeners and routing
- `waf.hcl` - Web Application Firewall
- `aurora-postgresql.hcl` - Aurora PostgreSQL clusters
- `kms.hcl` - KMS encryption keys
- `iam-role.hcl` - IAM roles (supports IRSA)
- `secrets-manager.hcl` - Secrets Manager secrets

## Mock Outputs

Dependencies use mock outputs to enable planning before infrastructure exists:

```hcl
dependency "general_networking" {
  config_path  = "../general-networking"
  mock_outputs = {
    vpc_id = "vpc-mock1234567890abc"
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
}
```

## When to Modify

**Modify helpers when:**
- Adding/removing module dependencies
- Changing module input parameters
- Updating module source paths

**Modify root.hcl instead for:**
- Environment-specific configuration values
- Changing business logic (instance sizes, replica counts, etc.)

**Use local inputs block for:**
- One-off overrides in a single environment

## Notes

- Helpers are Terragrunt configuration, not Terraform modules
- `iam-role.hcl` supports multiple role types via component-based mapping
- Mock outputs enable planning before dependencies exist
