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
# Locals
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # All networking configuration comes from root.hcl networking_config
  vpc_name                  = local.root.inputs.networking_config.vpc_name
  vpc_cidr                  = local.root.inputs.networking_config.vpc_cidr
  availability_zones        = local.root.inputs.networking_config.availability_zones
  public_subnet_cidrs       = local.root.inputs.networking_config.public_subnet_cidrs
  private_app_subnet_cidrs  = local.root.inputs.networking_config.private_app_subnet_cidrs
  private_data_subnet_cidrs = local.root.inputs.networking_config.private_data_subnet_cidrs
  enable_nat_gateway        = local.root.inputs.networking_config.enable_nat_gateway
  single_nat_gateway        = local.root.inputs.networking_config.single_nat_gateway

  # Tags from root (inherited automatically via root.hcl inputs)
  # common_tags
}
