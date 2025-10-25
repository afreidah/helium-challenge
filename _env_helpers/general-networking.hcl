# -----------------------------------------------------------------------------
# GENERAL NETWORKING ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
#
# This file provides the terraform source and default configuration for the
# general-networking module across all environments. It handles VPC creation,
# subnet allocation across three tiers (public, private-app, private-data),
# and NAT Gateway configuration for high availability.
#
# Directory Structure Expected:
#   <environment>/<region>/general-networking/terragrunt.hcl
#
# The child terragrunt.hcl only needs:
#   include "root" { path = find_in_parent_folders("root.hcl") }
#   include "general_networking" { path = "${get_repo_root()}/_env_helpers/general-networking.hcl" }
#
# Optional overrides can be added in the child file for specific environments.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/general-networking"
}

# -----------------------------------------------------------------------------
# Local Environment
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# MODULE INPUTS
# -----------------------------------------------------------------------------

inputs = {
  # VPC Configuration (provided by root.hcl per-environment)
  vpc_name = local.root.inputs.vpc_name
  vpc_cidr = local.root.inputs.vpc_cidr

  # Availability Zones (constructed in root.hcl from region)
  availability_zones = local.root.inputs.availability_zones

  # Public Subnets - /24 per AZ (256 IPs each)
  # For NAT Gateways, ALBs, bastion hosts
  public_subnet_cidrs = local.root.inputs.public_subnet_cidrs

  # Private Application Subnets - /20 per AZ (4,096 IPs each)
  # For EKS nodes, EC2 instances, containers, etc
  private_app_subnet_cidrs = local.root.inputs.private_app_subnet_cidrs

  # Private Data Subnets - /24 per AZ (256 IPs each)
  # For Aurora PostgreSQL, nd other data stores
  private_data_subnet_cidrs = local.root.inputs.private_data_subnet_cidrs

  # NAT Gateway Configuration
  enable_nat_gateway = local.root.inputs.enable_nat_gateway
  single_nat_gateway = local.root.inputs.single_nat_gateway
}

