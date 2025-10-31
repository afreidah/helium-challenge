# -----------------------------------------------------------------------------
# AURORA POSTGRESQL ENVIRONMENT HELPER
# -----------------------------------------------------------------------------
# This helper creates an Aurora PostgreSQL cluster with configuration defined
# in root.hcl and dependencies on general-networking and kms.
# -----------------------------------------------------------------------------

terraform {
  source = "${get_repo_root()}/modules/aurora-postgresql"
}

# -----------------------------------------------------------------------------
# Locals
# -----------------------------------------------------------------------------

locals {
  root = read_terragrunt_config(find_in_parent_folders("root.hcl"))
}

# -----------------------------------------------------------------------------
# Dependencies
# -----------------------------------------------------------------------------

dependency "general_networking" {
  config_path = "../general-networking"

  mock_outputs = {
    vpc_id                  = "vpc-12345678"
    private_data_subnet_ids = ["subnet-12345678", "subnet-87654321"] # Add this
  }
  mock_outputs_allowed_terraform_commands = ["init", "validate", "plan"]
  mock_outputs_merge_strategy_with_state  = "shallow"
}

dependency "kms" {
  config_path  = "../kms"
  skip_outputs = true

  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
    key_id  = "12345678-1234-1234-1234-123456789012"
  }
}

dependency "security_groups_aurora" {
  config_path  = "../security-groups-aurora"
  skip_outputs = true

  mock_outputs = {
    security_group_id = "sg-12345678"
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # Cluster identifier from environment/region
  cluster_identifier = "${local.root.inputs.environment}-${local.root.inputs.region}-aurora-pg"

  # Database configuration
  database_name   = replace("${local.root.inputs.environment}_db", "-", "_")
  master_username = "dbadmin"
  master_password = get_env("AURORA_MASTER_PASSWORD", "ChangeMe123!")

  # All Aurora configuration from root.hcl aurora_config
  engine_version                        = local.root.inputs.aurora_config.engine_version
  engine_mode                           = "provisioned"
  port                                  = local.root.inputs.aurora_config.port
  instance_count                        = local.root.inputs.aurora_config.instance_count
  instance_class                        = local.root.inputs.aurora_config.instance_class
  storage_encrypted                     = local.root.inputs.aurora_config.storage_encrypted
  storage_type                          = local.root.inputs.aurora_config.storage_type
  kms_key_id                            = dependency.kms.outputs.key_arn
  publicly_accessible                   = local.root.inputs.aurora_config.publicly_accessible
  availability_zones                    = null
  backup_retention_period               = local.root.inputs.aurora_config.backup_retention_period
  preferred_backup_window               = local.root.inputs.aurora_config.preferred_backup_window
  preferred_maintenance_window          = local.root.inputs.aurora_config.preferred_maintenance_window
  skip_final_snapshot                   = local.root.inputs.aurora_config.skip_final_snapshot
  enabled_cloudwatch_logs_exports       = local.root.inputs.aurora_config.enabled_cloudwatch_logs_exports
  performance_insights_enabled          = local.root.inputs.aurora_config.performance_insights_enabled
  performance_insights_retention_period = local.root.inputs.aurora_config.performance_insights_retention_period
  performance_insights_kms_key_id       = dependency.kms.outputs.key_arn
  monitoring_interval                   = local.root.inputs.aurora_config.monitoring_interval
  monitoring_role_arn                   = local.root.inputs.aurora_config.monitoring_interval > 0 ? "arn:aws:iam::${get_aws_account_id()}:role/rds-monitoring-role" : null
  iam_database_authentication_enabled   = local.root.inputs.aurora_config.iam_database_authentication_enabled
  auto_minor_version_upgrade            = local.root.inputs.aurora_config.auto_minor_version_upgrade
  allow_major_version_upgrade           = local.root.inputs.aurora_config.allow_major_version_upgrade
  apply_immediately                     = local.root.inputs.aurora_config.apply_immediately
  deletion_protection                   = local.root.inputs.aurora_config.deletion_protection

  # Network configuration from dependency
  vpc_security_group_ids     = [dependency.security_groups_aurora.outputs.security_group_id]
  db_subnet_group_subnet_ids = dependency.general_networking.outputs.private_data_subnet_ids

  # Parameter groups (null = use AWS defaults)
  db_cluster_parameter_group_name = null
  db_parameter_group_name         = null

  # Global database
  global_cluster_identifier = null

  # Serverless v2 scaling
  serverlessv2_scaling_configuration = null

  # Core identity from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
