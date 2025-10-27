# -----------------------------------------------------------------------------
# AURORA POSTGRESQL MODULE VARIABLES
# -----------------------------------------------------------------------------
#
# This file defines input variables for the Aurora PostgreSQL cluster module,
# including cluster configuration, instance settings, storage options, backup
# configuration, networking, monitoring, and high availability settings.
#
# Variable Categories:
#   - Cluster Configuration: Identifier, engine, and mode
#   - Database Configuration: Name, credentials, and port
#   - Instance Configuration: Count, class, and placement
#   - Storage Configuration: Encryption and storage type
#   - Network Configuration: VPC, subnets, and security groups
#   - Backup Configuration: Retention, windows, and snapshots
#   - Monitoring Configuration: Performance Insights and enhanced monitoring
#   - High Availability: Multi-AZ, failover, and global database
#   - Tagging: Resource tags for organization
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# CLUSTER CONFIGURATION
# -----------------------------------------------------------------------------

variable "cluster_identifier" {
  description = "Unique identifier for the Aurora cluster"
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]*$", var.cluster_identifier))
    error_message = "Cluster identifier must start with a letter, contain only lowercase letters, numbers, and hyphens."
  }

  validation {
    condition     = length(var.cluster_identifier) >= 1 && length(var.cluster_identifier) <= 63
    error_message = "Cluster identifier must be between 1 and 63 characters."
  }
}

variable "engine_version" {
  description = "Aurora PostgreSQL engine version"
  type        = string

  validation {
    condition     = can(regex("^[0-9]+\\.[0-9]+", var.engine_version))
    error_message = "Engine version must be in the format X.Y or X.Y.Z (e.g., 15.4, 14.9)."
  }
}

variable "engine_mode" {
  description = "Engine mode for Aurora cluster (provisioned or serverless)"
  type        = string
  default     = "provisioned"

  validation {
    condition     = contains(["provisioned", "serverless"], var.engine_mode)
    error_message = "Engine mode must be either 'provisioned' or 'serverless'."
  }
}

# -----------------------------------------------------------------------------
# DATABASE CONFIGURATION
# -----------------------------------------------------------------------------

variable "database_name" {
  description = "Name of the default database to create"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.database_name))
    error_message = "Database name must start with a letter and contain only alphanumeric characters and underscores."
  }

  validation {
    condition     = length(var.database_name) >= 1 && length(var.database_name) <= 63
    error_message = "Database name must be between 1 and 63 characters."
  }
}

variable "master_username" {
  description = "Master username for the database"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z][a-zA-Z0-9_]*$", var.master_username))
    error_message = "Master username must start with a letter and contain only alphanumeric characters and underscores."
  }

  validation {
    condition     = length(var.master_username) >= 1 && length(var.master_username) <= 16
    error_message = "Master username must be between 1 and 16 characters."
  }

  validation {
    condition     = !contains(["admin", "root", "superuser", "postgres"], lower(var.master_username))
    error_message = "Master username cannot be a reserved word (admin, root, superuser, postgres)."
  }
}

variable "master_password" {
  description = "Master password for the database"
  type        = string
  sensitive   = true

  validation {
    condition     = length(var.master_password) >= 8 && length(var.master_password) <= 128
    error_message = "Master password must be between 8 and 128 characters."
  }

  validation {
    condition     = can(regex("[A-Z]", var.master_password)) && can(regex("[a-z]", var.master_password)) && can(regex("[0-9]", var.master_password))
    error_message = "Master password must contain at least one uppercase letter, one lowercase letter, and one number."
  }
}

variable "port" {
  description = "Database port"
  type        = number
  default     = 5432

  validation {
    condition     = var.port >= 1150 && var.port <= 65535
    error_message = "Port must be between 1150 and 65535."
  }
}

# -----------------------------------------------------------------------------
# INSTANCE CONFIGURATION
# -----------------------------------------------------------------------------

variable "instance_count" {
  description = "Number of cluster instances to create (1 writer + N readers)"
  type        = number
  default     = 2

  validation {
    condition     = var.instance_count >= 1 && var.instance_count <= 15
    error_message = "Instance count must be between 1 and 15."
  }
}

variable "instance_class" {
  description = "Instance class for cluster instances"
  type        = string

  validation {
    condition     = can(regex("^db\\.(t3|t4g|r5|r6g|r6i|r7g|x2g|serverless)", var.instance_class))
    error_message = "Instance class must be a valid Aurora instance type (e.g., db.r6g.large, db.serverless)."
  }
}

variable "availability_zones" {
  description = "List of availability zones for instance placement (optional, distributes instances if provided)"
  type        = list(string)
  default     = null

  validation {
    condition     = var.availability_zones == null || length(var.availability_zones) >= 2
    error_message = "If specified, at least 2 availability zones must be provided for high availability."
  }
}

# -----------------------------------------------------------------------------
# STORAGE CONFIGURATION
# -----------------------------------------------------------------------------

variable "storage_encrypted" {
  description = "Enable storage encryption"
  type        = bool
  default     = true
}

variable "kms_key_id" {
  description = "KMS key ID for storage encryption (uses AWS managed key if not specified)"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_id == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.kms_key_id))
    error_message = "KMS key ID must be a valid KMS key ARN."
  }
}

variable "storage_type" {
  description = "Storage type (aurora or aurora-iopt1 for I/O optimized)"
  type        = string
  default     = "aurora"

  validation {
    condition     = contains(["aurora", "aurora-iopt1"], var.storage_type)
    error_message = "Storage type must be 'aurora' or 'aurora-iopt1'."
  }
}

# -----------------------------------------------------------------------------
# NETWORK CONFIGURATION
# -----------------------------------------------------------------------------

variable "vpc_security_group_ids" {
  description = "List of VPC security group IDs to associate with the cluster"
  type        = list(string)

  validation {
    condition     = length(var.vpc_security_group_ids) > 0
    error_message = "At least one VPC security group ID must be provided."
  }
}

variable "db_subnet_group_subnet_ids" {
  description = "List of subnet IDs for the DB subnet group"
  type        = list(string)

  validation {
    condition     = length(var.db_subnet_group_subnet_ids) >= 2
    error_message = "At least 2 subnet IDs must be provided for high availability."
  }
}

variable "publicly_accessible" {
  description = "Make cluster instances publicly accessible"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# BACKUP CONFIGURATION
# -----------------------------------------------------------------------------

variable "backup_retention_period" {
  description = "Backup retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = var.backup_retention_period >= 1 && var.backup_retention_period <= 35
    error_message = "Backup retention period must be between 1 and 35 days."
  }
}

variable "preferred_backup_window" {
  description = "Preferred backup window (format: hh24:mi-hh24:mi)"
  type        = string
  default     = "03:00-04:00"

  validation {
    condition     = can(regex("^([0-1][0-9]|2[0-3]):[0-5][0-9]-([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.preferred_backup_window))
    error_message = "Backup window must be in format HH:MM-HH:MM (e.g., 03:00-04:00)."
  }
}

variable "preferred_maintenance_window" {
  description = "Preferred maintenance window (format: ddd:hh24:mi-ddd:hh24:mi)"
  type        = string
  default     = "sun:04:00-sun:05:00"

  validation {
    condition     = can(regex("^(mon|tue|wed|thu|fri|sat|sun):([0-1][0-9]|2[0-3]):[0-5][0-9]-(mon|tue|wed|thu|fri|sat|sun):([0-1][0-9]|2[0-3]):[0-5][0-9]$", var.preferred_maintenance_window))
    error_message = "Maintenance window must be in format ddd:HH:MM-ddd:HH:MM (e.g., sun:04:00-sun:05:00)."
  }
}

variable "skip_final_snapshot" {
  description = "Skip final snapshot on cluster deletion"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# PARAMETER GROUPS
# -----------------------------------------------------------------------------

variable "db_cluster_parameter_group_name" {
  description = "Name of the DB cluster parameter group to associate"
  type        = string
  default     = null
}

variable "db_parameter_group_name" {
  description = "Name of the DB parameter group to associate with instances"
  type        = string
  default     = null
}

# -----------------------------------------------------------------------------
# CLOUDWATCH LOGS CONFIGURATION
# -----------------------------------------------------------------------------

variable "enabled_cloudwatch_logs_exports" {
  description = "List of log types to export to CloudWatch (postgresql)"
  type        = list(string)
  default     = ["postgresql"]

  validation {
    condition     = alltrue([for log in var.enabled_cloudwatch_logs_exports : contains(["postgresql"], log)])
    error_message = "For Aurora PostgreSQL, only 'postgresql' log type is supported."
  }
}

# -----------------------------------------------------------------------------
# PERFORMANCE INSIGHTS CONFIGURATION
# -----------------------------------------------------------------------------

variable "performance_insights_enabled" {
  description = "Enable Performance Insights"
  type        = bool
  default     = true
}

variable "performance_insights_retention_period" {
  description = "Performance Insights retention period in days"
  type        = number
  default     = 7

  validation {
    condition     = contains([7, 31, 62, 93, 124, 155, 186, 217, 248, 279, 310, 341, 372, 403, 434, 465, 496, 527, 558, 589, 620, 651, 682, 713, 731], var.performance_insights_retention_period)
    error_message = "Performance Insights retention must be 7 days (free tier) or a multiple of 31 days up to 731 days."
  }
}

variable "performance_insights_kms_key_id" {
  description = "KMS key ID for Performance Insights encryption"
  type        = string
  default     = null

  validation {
    condition     = var.performance_insights_kms_key_id == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.performance_insights_kms_key_id))
    error_message = "Performance Insights KMS key ID must be a valid KMS key ARN."
  }
}

# -----------------------------------------------------------------------------
# ENHANCED MONITORING CONFIGURATION
# -----------------------------------------------------------------------------

variable "monitoring_interval" {
  description = "Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60)"
  type        = number
  default     = 60

  validation {
    condition     = contains([0, 1, 5, 10, 15, 30, 60], var.monitoring_interval)
    error_message = "Monitoring interval must be 0 (disabled), 1, 5, 10, 15, 30, or 60 seconds."
  }
}

variable "monitoring_role_arn" {
  description = "IAM role ARN for enhanced monitoring"
  type        = string
  default     = null

  validation {
    condition     = var.monitoring_role_arn == null || can(regex("^arn:aws:iam::[0-9]{12}:role/", var.monitoring_role_arn))
    error_message = "Monitoring role ARN must be a valid IAM role ARN."
  }
}

# -----------------------------------------------------------------------------
# IAM DATABASE AUTHENTICATION
# -----------------------------------------------------------------------------

variable "iam_database_authentication_enabled" {
  description = "Enable IAM database authentication"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# VERSION MANAGEMENT
# -----------------------------------------------------------------------------

variable "auto_minor_version_upgrade" {
  description = "Automatically upgrade minor engine versions"
  type        = bool
  default     = false
}

variable "allow_major_version_upgrade" {
  description = "Allow major version upgrades"
  type        = bool
  default     = false
}

variable "apply_immediately" {
  description = "Apply changes immediately instead of during maintenance window"
  type        = bool
  default     = false
}

# -----------------------------------------------------------------------------
# DELETION PROTECTION
# -----------------------------------------------------------------------------

variable "deletion_protection" {
  description = "Enable deletion protection for the cluster"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# GLOBAL DATABASE CONFIGURATION
# -----------------------------------------------------------------------------

variable "global_cluster_identifier" {
  description = "Global database identifier for multi-region deployments"
  type        = string
  default     = null

  validation {
    condition     = var.global_cluster_identifier == null || can(regex("^[a-z][a-z0-9-]*$", var.global_cluster_identifier))
    error_message = "Global cluster identifier must start with a letter and contain only lowercase letters, numbers, and hyphens."
  }
}

# -----------------------------------------------------------------------------
# SERVERLESS V2 SCALING CONFIGURATION
# -----------------------------------------------------------------------------

variable "serverlessv2_scaling_configuration" {
  description = "Serverless v2 scaling configuration (min and max capacity in ACUs)"
  type = object({
    min_capacity = number
    max_capacity = number
  })
  default = null

  validation {
    condition = (
      var.serverlessv2_scaling_configuration == null ||
      (var.serverlessv2_scaling_configuration.min_capacity >= 0.5 &&
        var.serverlessv2_scaling_configuration.max_capacity <= 128 &&
      var.serverlessv2_scaling_configuration.min_capacity <= var.serverlessv2_scaling_configuration.max_capacity)
    )
    error_message = "Serverless v2 scaling: min_capacity must be >= 0.5, max_capacity must be <= 128, and min must be <= max."
  }
}

# -----------------------------------------------------------------------------
# TAGGING
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default     = {}
}
