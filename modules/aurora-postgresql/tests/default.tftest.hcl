# -----------------------------------------------------------------------------
# AURORA POSTGRESQL MODULE TEST SUITE
# -----------------------------------------------------------------------------
#
# Tests the Aurora PostgreSQL module for conditional logic, computed naming,
# instance distribution, failover configuration, and multi-instance behavior.
# Does NOT test simple variable passthrough - focuses on module logic.
# -----------------------------------------------------------------------------

# Test variables
variables {
  test_cluster_id = "test-aurora-cluster"
  test_vpc_id     = "vpc-12345678"
  test_subnet_ids = ["subnet-11111111", "subnet-22222222", "subnet-33333333"]
  test_sg_ids     = ["sg-12345678"]
  test_kms_key_id = "arn:aws:kms:us-east-1:123456789012:key/12345678-1234-1234-1234-123456789012"
  test_azs        = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

# ----------------------------------------------------------------
# Subnet group naming convention
# Expected: Subnet group name follows cluster-subnet-group pattern
# ----------------------------------------------------------------
run "subnet_group_naming" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
  }

  # Assert subnet group follows naming convention
  assert {
    condition     = aws_db_subnet_group.this.name == "test-aurora-cluster-subnet-group"
    error_message = "Subnet group should follow {cluster_identifier}-subnet-group naming"
  }

  # Assert subnet group contains all provided subnets
  assert {
    condition     = length(aws_db_subnet_group.this.subnet_ids) == 3
    error_message = "Subnet group should include all provided subnet IDs"
  }
}

# ----------------------------------------------------------------
# Single instance deployment
# Expected: One instance created when instance_count = 1
# ----------------------------------------------------------------
run "single_instance" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
  }

  # Assert exactly one instance is created
  assert {
    condition     = length(aws_rds_cluster_instance.this) == 1
    error_message = "Should create exactly 1 instance when instance_count = 1"
  }

  # Assert instance naming follows pattern
  assert {
    condition     = aws_rds_cluster_instance.this[0].identifier == "test-aurora-cluster-instance-1"
    error_message = "Instance should be named {cluster_id}-instance-1"
  }
}

# ----------------------------------------------------------------
# Multi-instance deployment with failover priority
# Expected: Multiple instances created with correct promotion tiers
# ----------------------------------------------------------------
run "multi_instance_failover" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 3
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
  }

  # Assert correct number of instances created
  assert {
    condition     = length(aws_rds_cluster_instance.this) == 3
    error_message = "Should create 3 instances when instance_count = 3"
  }

  # Assert first instance has promotion tier 0 (highest priority)
  assert {
    condition     = aws_rds_cluster_instance.this[0].promotion_tier == 0
    error_message = "First instance should have promotion_tier = 0 (writer priority)"
  }

  # Assert second instance has promotion tier 1
  assert {
    condition     = aws_rds_cluster_instance.this[1].promotion_tier == 1
    error_message = "Second instance should have promotion_tier = 1"
  }

  # Assert third instance has promotion tier 2
  assert {
    condition     = aws_rds_cluster_instance.this[2].promotion_tier == 2
    error_message = "Third instance should have promotion_tier = 2 (lowest priority)"
  }

  # Assert instance naming increments correctly
  assert {
    condition     = aws_rds_cluster_instance.this[0].identifier == "test-aurora-cluster-instance-1"
    error_message = "First instance should be instance-1"
  }

  assert {
    condition     = aws_rds_cluster_instance.this[2].identifier == "test-aurora-cluster-instance-3"
    error_message = "Third instance should be instance-3"
  }
}

# ----------------------------------------------------------------
# Availability zone distribution
# Expected: Instances distributed across provided AZs
# ----------------------------------------------------------------
run "az_distribution" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 3
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
    availability_zones         = var.test_azs
  }

  # Assert first instance in first AZ
  assert {
    condition     = aws_rds_cluster_instance.this[0].availability_zone == "us-east-1a"
    error_message = "First instance should be placed in first AZ"
  }

  # Assert second instance in second AZ
  assert {
    condition     = aws_rds_cluster_instance.this[1].availability_zone == "us-east-1b"
    error_message = "Second instance should be placed in second AZ"
  }

  # Assert third instance in third AZ
  assert {
    condition     = aws_rds_cluster_instance.this[2].availability_zone == "us-east-1c"
    error_message = "Third instance should be placed in third AZ"
  }
}

# ----------------------------------------------------------------
# No AZ specified - AWS places instances
# Expected: AZ assignment handled by AWS
# ----------------------------------------------------------------
run "no_az_specified" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 2
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
    availability_zones         = null
  }

  # Assert instances are created (AWS will auto-place in AZs)
  assert {
    condition     = length(aws_rds_cluster_instance.this) == 2
    error_message = "Should create 2 instances even when availability_zones is null"
  }
}

# ----------------------------------------------------------------
# Performance Insights conditional configuration
# Expected: PI settings applied only when enabled
# ----------------------------------------------------------------
run "performance_insights_enabled" {
  command = plan

  variables {
    cluster_identifier                    = var.test_cluster_id
    engine_version                        = "15.4"
    instance_count                        = 1
    instance_class                        = "db.r6g.large"
    database_name                         = "testdb"
    master_username                       = "dbadmin"
    master_password                       = "TestPass123!"
    vpc_security_group_ids                = var.test_sg_ids
    db_subnet_group_subnet_ids            = var.test_subnet_ids
    performance_insights_enabled          = true
    performance_insights_retention_period = 31
    performance_insights_kms_key_id       = var.test_kms_key_id
  }

  # Assert PI is enabled
  assert {
    condition     = aws_rds_cluster_instance.this[0].performance_insights_enabled == true
    error_message = "Performance Insights should be enabled when specified"
  }
}

# ----------------------------------------------------------------
# Performance Insights disabled
# Expected: PI is disabled
# ----------------------------------------------------------------
run "performance_insights_disabled" {
  command = plan

  variables {
    cluster_identifier                    = var.test_cluster_id
    engine_version                        = "15.4"
    instance_count                        = 1
    instance_class                        = "db.r6g.large"
    database_name                         = "testdb"
    master_username                       = "dbadmin"
    master_password                       = "TestPass123!"
    vpc_security_group_ids                = var.test_sg_ids
    db_subnet_group_subnet_ids            = var.test_subnet_ids
    performance_insights_enabled          = false
    performance_insights_retention_period = 31
    performance_insights_kms_key_id       = var.test_kms_key_id
  }

  # Assert PI is disabled
  assert {
    condition     = aws_rds_cluster_instance.this[0].performance_insights_enabled == false
    error_message = "Performance Insights should be disabled when set to false"
  }
}

# ----------------------------------------------------------------
# Enhanced monitoring conditional
# Expected: Monitoring role set only when interval > 0
# ----------------------------------------------------------------
run "enhanced_monitoring_enabled" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
    monitoring_interval        = 60
    monitoring_role_arn        = "arn:aws:iam::123456789012:role/rds-monitoring-role"
  }

  # Assert monitoring interval is set
  assert {
    condition     = aws_rds_cluster_instance.this[0].monitoring_interval == 60
    error_message = "Monitoring interval should be set when specified"
  }

  # Assert monitoring role is set when interval > 0 (logic test)
  assert {
    condition     = aws_rds_cluster_instance.this[0].monitoring_role_arn == "arn:aws:iam::123456789012:role/rds-monitoring-role"
    error_message = "Monitoring role ARN should be set when monitoring_interval > 0"
  }
}

# ----------------------------------------------------------------
# Enhanced monitoring disabled
# Expected: Monitoring is disabled
# ----------------------------------------------------------------
run "enhanced_monitoring_disabled" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
    monitoring_interval        = 0
    monitoring_role_arn        = "arn:aws:iam::123456789012:role/rds-monitoring-role"
  }

  # Assert monitoring interval is 0
  assert {
    condition     = aws_rds_cluster_instance.this[0].monitoring_interval == 0
    error_message = "Monitoring interval should be 0 when disabled"
  }
}

# ----------------------------------------------------------------
# Serverless v2 scaling configuration
# Expected: Scaling block created only when serverlessv2_scaling_configuration provided
# ----------------------------------------------------------------
run "serverlessv2_scaling_enabled" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.serverless"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
    serverlessv2_scaling_configuration = {
      min_capacity = 0.5
      max_capacity = 16
    }
  }

  # Assert serverless scaling configuration exists (logic test)
  assert {
    condition     = length(aws_rds_cluster.this.serverlessv2_scaling_configuration) == 1
    error_message = "Serverless v2 scaling block should exist when configuration provided"
  }

  # Assert min capacity is set correctly
  assert {
    condition     = aws_rds_cluster.this.serverlessv2_scaling_configuration[0].min_capacity == 0.5
    error_message = "Min capacity should be configured when serverless v2 scaling enabled"
  }

  # Assert max capacity is set correctly
  assert {
    condition     = aws_rds_cluster.this.serverlessv2_scaling_configuration[0].max_capacity == 16
    error_message = "Max capacity should be configured when serverless v2 scaling enabled"
  }
}

# ----------------------------------------------------------------
# Serverless v2 scaling disabled
# Expected: No scaling block when serverlessv2_scaling_configuration is null
# ----------------------------------------------------------------
run "serverlessv2_scaling_disabled" {
  command = plan

  variables {
    cluster_identifier                 = var.test_cluster_id
    engine_version                     = "15.4"
    instance_count                     = 1
    instance_class                     = "db.r6g.large"
    database_name                      = "testdb"
    master_username                    = "dbadmin"
    master_password                    = "TestPass123!"
    vpc_security_group_ids             = var.test_sg_ids
    db_subnet_group_subnet_ids         = var.test_subnet_ids
    serverlessv2_scaling_configuration = null
  }

  # Assert no serverless scaling configuration (logic test)
  assert {
    condition     = length(aws_rds_cluster.this.serverlessv2_scaling_configuration) == 0
    error_message = "Serverless v2 scaling block should not exist when configuration is null (conditional logic)"
  }
}

# ----------------------------------------------------------------
# Final snapshot identifier generation
# Expected: Snapshot created when not skipping
# ----------------------------------------------------------------
run "final_snapshot_with_identifier" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
    skip_final_snapshot        = false
  }

  # Assert skip_final_snapshot is false
  assert {
    condition     = aws_rds_cluster.this.skip_final_snapshot == false
    error_message = "Should not skip final snapshot when set to false"
  }
}

# ----------------------------------------------------------------
# Skip final snapshot
# Expected: Snapshot identifier is null when skipping
# ----------------------------------------------------------------
run "skip_final_snapshot" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
    skip_final_snapshot        = true
  }

  # Assert skip_final_snapshot is true
  assert {
    condition     = aws_rds_cluster.this.skip_final_snapshot == true
    error_message = "Should skip final snapshot when set to true"
  }

  # Assert final snapshot identifier is null when skipping (logic test)
  assert {
    condition     = aws_rds_cluster.this.final_snapshot_identifier == null
    error_message = "Final snapshot identifier should be null when skip_final_snapshot = true (conditional logic)"
  }
}

# ----------------------------------------------------------------
# Copy tags to snapshot behavior
# Expected: Always enabled for backups
# ----------------------------------------------------------------
run "copy_tags_to_snapshot" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 1
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
  }

  # Assert tags are copied to snapshots (hardcoded logic)
  assert {
    condition     = aws_rds_cluster.this.copy_tags_to_snapshot == true
    error_message = "Tags should always be copied to snapshots for consistency"
  }
}

# ----------------------------------------------------------------
# Instance inherits cluster engine settings
# Expected: Instances use cluster engine and version
# ----------------------------------------------------------------
run "instance_inherits_cluster_engine" {
  command = plan

  variables {
    cluster_identifier         = var.test_cluster_id
    engine_version             = "15.4"
    instance_count             = 2
    instance_class             = "db.r6g.large"
    database_name              = "testdb"
    master_username            = "dbadmin"
    master_password            = "TestPass123!"
    vpc_security_group_ids     = var.test_sg_ids
    db_subnet_group_subnet_ids = var.test_subnet_ids
  }

  # Assert instance inherits cluster engine (logic test)
  assert {
    condition     = aws_rds_cluster_instance.this[0].engine == aws_rds_cluster.this.engine
    error_message = "Instance should inherit engine from cluster"
  }

  # Assert instance inherits cluster engine version (logic test)
  assert {
    condition     = aws_rds_cluster_instance.this[0].engine_version == aws_rds_cluster.this.engine_version
    error_message = "Instance should inherit engine_version from cluster"
  }

  # Assert engine is aurora-postgresql
  assert {
    condition     = aws_rds_cluster.this.engine == "aurora-postgresql"
    error_message = "Cluster should use aurora-postgresql engine"
  }
}
