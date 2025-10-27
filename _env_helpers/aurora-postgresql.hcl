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
  config_path  = "../general-networking"
  skip_outputs = true

  mock_outputs = {
    vpc_id                  = "vpc-12345678"
    private_data_subnet_ids = ["subnet-12345678", "subnet-87654321"]
    aurora_postgresql_sg_id = "sg-12345678"
  }
}

dependency "kms" {
  config_path  = "../kms"
  skip_outputs = true

  mock_outputs = {
    key_arn = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  }
}

# -----------------------------------------------------------------------------
# Inputs
# -----------------------------------------------------------------------------

inputs = {
  # Cluster identifier from environment/region
  cluster_identifier = "${local.root.locals.environment}-${local.root.locals.region}-aurora-pg"

  # Database configuration
  database_name   = replace("${local.root.locals.environment}_db", "-", "_")
  master_username = "dbadmin"
  master_password = get_env("AURORA_MASTER_PASSWORD", "CHANGE_ME_IN_PRODUCTION")

  # Engine configuration from root.hcl
  engine_version = local.root.locals.aurora_defaults.engine_version
  engine_mode    = "provisioned"
  port           = local.root.locals.aurora_defaults.port

  # Instance configuration from root.hcl
  instance_count = local.root.inputs.aurora_config.instance_count
  instance_class = local.root.inputs.aurora_config.instance_class

  # Storage configuration
  storage_encrypted = local.root.locals.aurora_defaults.storage_encrypted
  storage_type      = local.root.locals.aurora_defaults.storage_type
  kms_key_id        = dependency.kms.outputs.key_arn

  # Network configuration from dependency
  vpc_security_group_ids     = [dependency.general_networking.outputs.aurora_postgresql_sg_id]
  db_subnet_group_subnet_ids = dependency.general_networking.outputs.private_data_subnet_ids
  publicly_accessible        = local.root.locals.aurora_defaults.publicly_accessible
  availability_zones         = null

  # Backup configuration from root.hcl
  backup_retention_period      = local.root.inputs.aurora_config.backup_retention_period
  preferred_backup_window      = local.root.locals.aurora_defaults.preferred_backup_window
  preferred_maintenance_window = local.root.locals.aurora_defaults.preferred_maintenance_window
  skip_final_snapshot          = local.root.inputs.aurora_config.skip_final_snapshot

  # Parameter groups (null = use AWS defaults)
  db_cluster_parameter_group_name = null
  db_parameter_group_name         = null

  # CloudWatch logs
  enabled_cloudwatch_logs_exports = local.root.locals.aurora_defaults.enabled_cloudwatch_logs_exports

  # Performance Insights from root.hcl
  performance_insights_enabled          = local.root.inputs.aurora_config.performance_insights_enabled
  performance_insights_retention_period = local.root.inputs.aurora_config.performance_insights_retention_period
  performance_insights_kms_key_id       = dependency.kms.outputs.key_arn

  # Enhanced monitoring from root.hcl
  monitoring_interval = local.root.inputs.aurora_config.monitoring_interval
  monitoring_role_arn = local.root.inputs.aurora_config.monitoring_interval > 0 ? "arn:aws:iam::${get_aws_account_id()}:role/rds-monitoring-role" : null

  # IAM database authentication
  iam_database_authentication_enabled = local.root.locals.aurora_defaults.iam_database_authentication_enabled

  # Version management
  auto_minor_version_upgrade  = local.root.locals.aurora_defaults.auto_minor_version_upgrade
  allow_major_version_upgrade = local.root.locals.aurora_defaults.allow_major_version_upgrade
  apply_immediately           = local.root.locals.aurora_defaults.apply_immediately

  # Deletion protection from root.hcl
  deletion_protection = local.root.inputs.aurora_config.deletion_protection

  # Global database
  global_cluster_identifier = null

  # Serverless v2 scaling
  serverlessv2_scaling_configuration = null

  # Tags from root (inherited automatically via root.hcl inputs)
  # environment, region, component, common_tags
}
