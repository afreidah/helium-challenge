# -----------------------------------------------------------------------------
# AURORA POSTGRESQL CLUSTER MODULE
# -----------------------------------------------------------------------------
#
# This module creates an Amazon Aurora PostgreSQL cluster with configurable
# cluster instances, dedicated subnet group, storage encryption, automated
# backups, and optional features including Global Database support, Performance
# Insights, enhanced monitoring, and IAM database authentication.
#
# Aurora provides a MySQL and PostgreSQL-compatible relational database built
# for the cloud with high performance, availability, and durability. The cluster
# architecture separates compute (instances) from storage, enabling rapid scaling
# and failover. Storage automatically scales from 10GB to 128TB.
#
# Components Created:
#   - Aurora Cluster: Shared storage layer and cluster configuration
#   - Cluster Instances: Individual compute nodes (writer and readers)
#   - DB Subnet Group: Network placement across availability zones
#   - CloudWatch Logs: Audit and error log export
#
# Features:
#   - Automatic failover with Multi-AZ deployment
#   - Read replicas for horizontal read scaling
#   - Continuous backup to Amazon S3
#   - Point-in-time recovery (PITR)
#   - Fast cloning from existing snapshots
#   - Backtrack capability (MySQL only)
#   - Global Database for multi-region deployments
#
# IMPORTANT: Master password changes are ignored in the lifecycle configuration
# to prevent unintended updates. Deletion protection should remain enabled for
# production clusters. Final snapshots are recommended before deletion unless
# explicitly skipped.
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# DB SUBNET GROUP
# -----------------------------------------------------------------------------

# Subnet group for Aurora cluster placement across availability zones
# Automatically created and named based on the cluster identifier
resource "aws_db_subnet_group" "this" {
  name       = "${var.cluster_identifier}-subnet-group"
  subnet_ids = var.db_subnet_group_subnet_ids

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_identifier}-subnet-group"
    }
  )
}

# -----------------------------------------------------------------------------
# AURORA CLUSTER
# -----------------------------------------------------------------------------

# Amazon Aurora cluster providing shared storage and configuration
# Manages backup, encryption, networking, and cluster-level settings
resource "aws_rds_cluster" "this" {
  cluster_identifier = var.cluster_identifier
  engine             = "aurora-postgresql"
  engine_version     = var.engine_version
  engine_mode        = var.engine_mode

  # -------------------------------------------------------------------------
  # DATABASE CONFIGURATION
  # -------------------------------------------------------------------------
  # Database name, credentials, and connection port
  database_name   = var.database_name
  master_username = var.master_username
  master_password = var.master_password
  port            = var.port

  # -------------------------------------------------------------------------
  # NETWORK CONFIGURATION
  # -------------------------------------------------------------------------
  # VPC placement, security groups, and accessibility
  vpc_security_group_ids = var.vpc_security_group_ids
  db_subnet_group_name   = aws_db_subnet_group.this.name

  # -------------------------------------------------------------------------
  # STORAGE CONFIGURATION
  # -------------------------------------------------------------------------
  # Encryption and storage type selection
  storage_encrypted = var.storage_encrypted
  kms_key_id        = var.kms_key_id
  storage_type      = var.storage_type

  # -------------------------------------------------------------------------
  # BACKUP CONFIGURATION
  # -------------------------------------------------------------------------
  # Automated backup retention, timing, and maintenance windows
  backup_retention_period      = var.backup_retention_period
  preferred_backup_window      = var.preferred_backup_window
  preferred_maintenance_window = var.preferred_maintenance_window

  # -------------------------------------------------------------------------
  # SNAPSHOT CONFIGURATION
  # -------------------------------------------------------------------------
  # Final snapshot behavior on cluster deletion
  skip_final_snapshot       = var.skip_final_snapshot
  final_snapshot_identifier = var.skip_final_snapshot ? null : "${var.cluster_identifier}-final-${formatdate("YYYY-MM-DD-hhmm", timestamp())}"

  # -------------------------------------------------------------------------
  # CLOUDWATCH LOGS CONFIGURATION
  # -------------------------------------------------------------------------
  # Export database logs to CloudWatch for monitoring
  enabled_cloudwatch_logs_exports = var.enabled_cloudwatch_logs_exports

  # -------------------------------------------------------------------------
  # IAM DATABASE AUTHENTICATION
  # -------------------------------------------------------------------------
  # Enable IAM-based database access
  iam_database_authentication_enabled = var.iam_database_authentication_enabled

  # -------------------------------------------------------------------------
  # BACKTRACK CONFIGURATION (PostgreSQL does not support backtrack)
  # -------------------------------------------------------------------------
  # Aurora PostgreSQL does not support backtrack feature

  # -------------------------------------------------------------------------
  # DELETION PROTECTION
  # -------------------------------------------------------------------------
  # Prevent accidental cluster deletion
  deletion_protection = var.deletion_protection

  # -------------------------------------------------------------------------
  # VERSION MANAGEMENT
  # -------------------------------------------------------------------------
  # Automatic minor version upgrade behavior
  allow_major_version_upgrade = var.allow_major_version_upgrade
  apply_immediately           = var.apply_immediately

  # -------------------------------------------------------------------------
  # PARAMETER GROUP
  # -------------------------------------------------------------------------
  # Cluster-level parameter group configuration
  db_cluster_parameter_group_name = var.db_cluster_parameter_group_name

  # -------------------------------------------------------------------------
  # SNAPSHOT COPY CONFIGURATION
  # -------------------------------------------------------------------------
  # Automatically copy cluster tags to automated backups and snapshots
  copy_tags_to_snapshot = true

  # -------------------------------------------------------------------------
  # GLOBAL DATABASE CONFIGURATION
  # -------------------------------------------------------------------------
  # Global database identifier for multi-region deployments
  global_cluster_identifier = var.global_cluster_identifier

  # -------------------------------------------------------------------------
  # SERVERLESS V2 SCALING (when engine_mode = "provisioned" with Serverless v2)
  # -------------------------------------------------------------------------
  dynamic "serverlessv2_scaling_configuration" {
    for_each = var.serverlessv2_scaling_configuration != null ? [var.serverlessv2_scaling_configuration] : []
    content {
      max_capacity = serverlessv2_scaling_configuration.value.max_capacity
      min_capacity = serverlessv2_scaling_configuration.value.min_capacity
    }
  }

  tags = merge(
    var.tags,
    {
      Name = var.cluster_identifier
    }
  )

  lifecycle {
    prevent_destroy = false
    ignore_changes  = [master_password, final_snapshot_identifier]
  }
}

# -----------------------------------------------------------------------------
# AURORA CLUSTER INSTANCES
# -----------------------------------------------------------------------------

# Aurora cluster instances providing compute capacity
# Writer instance handles read-write operations, reader instances handle read-only
resource "aws_rds_cluster_instance" "this" {
  count = var.instance_count

  identifier         = "${var.cluster_identifier}-instance-${count.index + 1}"
  cluster_identifier = aws_rds_cluster.this.id
  engine             = aws_rds_cluster.this.engine
  engine_version     = aws_rds_cluster.this.engine_version
  instance_class     = var.instance_class

  # -------------------------------------------------------------------------
  # NETWORK CONFIGURATION
  # -------------------------------------------------------------------------
  # Public accessibility setting
  publicly_accessible = var.publicly_accessible

  # -------------------------------------------------------------------------
  # PARAMETER GROUP
  # -------------------------------------------------------------------------
  # Instance-level parameter group configuration
  db_parameter_group_name = var.db_parameter_group_name

  # -------------------------------------------------------------------------
  # PERFORMANCE INSIGHTS CONFIGURATION
  # -------------------------------------------------------------------------
  # Enhanced performance monitoring and analysis
  performance_insights_enabled          = var.performance_insights_enabled
  performance_insights_retention_period = var.performance_insights_enabled ? var.performance_insights_retention_period : null
  performance_insights_kms_key_id       = var.performance_insights_enabled ? var.performance_insights_kms_key_id : null

  # -------------------------------------------------------------------------
  # ENHANCED MONITORING CONFIGURATION
  # -------------------------------------------------------------------------
  # OS-level metrics collection via CloudWatch
  monitoring_interval = var.monitoring_interval
  monitoring_role_arn = var.monitoring_interval > 0 ? var.monitoring_role_arn : null

  # -------------------------------------------------------------------------
  # VERSION MANAGEMENT
  # -------------------------------------------------------------------------
  # Automatic minor version upgrade behavior
  auto_minor_version_upgrade = var.auto_minor_version_upgrade

  # -------------------------------------------------------------------------
  # PROMOTION TIER
  # -------------------------------------------------------------------------
  # Failover priority (0-15, lower is higher priority)
  promotion_tier = count.index

  # -------------------------------------------------------------------------
  # AVAILABILITY ZONE PLACEMENT
  # -------------------------------------------------------------------------
  # Distribute instances across AZs for high availability
  availability_zone = var.availability_zones != null && length(var.availability_zones) > 0 ? element(var.availability_zones, count.index) : null

  tags = merge(
    var.tags,
    {
      Name = "${var.cluster_identifier}-instance-${count.index + 1}"
    }
  )
}
