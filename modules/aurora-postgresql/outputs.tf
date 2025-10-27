# -----------------------------------------------------------------------------
# AURORA POSTGRESQL MODULE OUTPUTS
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# CLUSTER OUTPUTS
# -----------------------------------------------------------------------------

output "cluster_id" {
  description = "Aurora cluster ID"
  value       = aws_rds_cluster.this.id
}

output "cluster_arn" {
  description = "Aurora cluster ARN"
  value       = aws_rds_cluster.this.arn
}

output "cluster_endpoint" {
  description = "Writer endpoint for the cluster (read-write)"
  value       = aws_rds_cluster.this.endpoint
}

output "cluster_reader_endpoint" {
  description = "Reader endpoint for the cluster (read-only, load-balanced)"
  value       = aws_rds_cluster.this.reader_endpoint
}

output "cluster_resource_id" {
  description = "Cluster resource ID"
  value       = aws_rds_cluster.this.cluster_resource_id
}

output "cluster_port" {
  description = "Database port"
  value       = aws_rds_cluster.this.port
}

output "cluster_database_name" {
  description = "Name of the default database"
  value       = aws_rds_cluster.this.database_name
}

output "cluster_master_username" {
  description = "Master username for the cluster"
  value       = aws_rds_cluster.this.master_username
  sensitive   = true
}

output "cluster_hosted_zone_id" {
  description = "Route 53 hosted zone ID for the cluster endpoint"
  value       = aws_rds_cluster.this.hosted_zone_id
}

output "cluster_engine_version" {
  description = "Actual engine version running on the cluster"
  value       = aws_rds_cluster.this.engine_version_actual
}

# -----------------------------------------------------------------------------
# INSTANCE OUTPUTS
# -----------------------------------------------------------------------------

output "instance_ids" {
  description = "List of cluster instance IDs"
  value       = aws_rds_cluster_instance.this[*].id
}

output "instance_arns" {
  description = "List of cluster instance ARNs"
  value       = aws_rds_cluster_instance.this[*].arn
}

output "instance_endpoints" {
  description = "List of cluster instance endpoints"
  value       = aws_rds_cluster_instance.this[*].endpoint
}

output "instance_availability_zones" {
  description = "List of availability zones for cluster instances"
  value       = aws_rds_cluster_instance.this[*].availability_zone
}

output "writer_instance_id" {
  description = "ID of the writer instance (first instance)"
  value       = length(aws_rds_cluster_instance.this) > 0 ? aws_rds_cluster_instance.this[0].id : null
}

output "writer_instance_endpoint" {
  description = "Endpoint of the writer instance"
  value       = length(aws_rds_cluster_instance.this) > 0 ? aws_rds_cluster_instance.this[0].endpoint : null
}

output "reader_instance_ids" {
  description = "List of reader instance IDs (all instances except first)"
  value       = length(aws_rds_cluster_instance.this) > 1 ? slice(aws_rds_cluster_instance.this[*].id, 1, length(aws_rds_cluster_instance.this)) : []
}

output "reader_instance_endpoints" {
  description = "List of reader instance endpoints (all instances except first)"
  value       = length(aws_rds_cluster_instance.this) > 1 ? slice(aws_rds_cluster_instance.this[*].endpoint, 1, length(aws_rds_cluster_instance.this)) : []
}

# -----------------------------------------------------------------------------
# SUBNET GROUP OUTPUTS
# -----------------------------------------------------------------------------

output "db_subnet_group_name" {
  description = "Name of the DB subnet group"
  value       = aws_db_subnet_group.this.name
}

output "db_subnet_group_arn" {
  description = "ARN of the DB subnet group"
  value       = aws_db_subnet_group.this.arn
}

# -----------------------------------------------------------------------------
# CONNECTION STRING HELPER
# -----------------------------------------------------------------------------

output "connection_string_writer" {
  description = "PostgreSQL connection string for writer endpoint (password not included)"
  value       = "postgresql://${aws_rds_cluster.this.master_username}@${aws_rds_cluster.this.endpoint}:${aws_rds_cluster.this.port}/${aws_rds_cluster.this.database_name}"
  sensitive   = true
}

output "connection_string_reader" {
  description = "PostgreSQL connection string for reader endpoint (password not included)"
  value       = "postgresql://${aws_rds_cluster.this.master_username}@${aws_rds_cluster.this.reader_endpoint}:${aws_rds_cluster.this.port}/${aws_rds_cluster.this.database_name}"
  sensitive   = true
}
