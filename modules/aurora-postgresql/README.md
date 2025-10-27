<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_db_subnet_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/db_subnet_group) | resource |
| [aws_rds_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster) | resource |
| [aws_rds_cluster_instance.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/rds_cluster_instance) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_allow_major_version_upgrade"></a> [allow\_major\_version\_upgrade](#input\_allow\_major\_version\_upgrade) | Allow major version upgrades | `bool` | `false` | no |
| <a name="input_apply_immediately"></a> [apply\_immediately](#input\_apply\_immediately) | Apply changes immediately instead of during maintenance window | `bool` | `false` | no |
| <a name="input_auto_minor_version_upgrade"></a> [auto\_minor\_version\_upgrade](#input\_auto\_minor\_version\_upgrade) | Automatically upgrade minor engine versions | `bool` | `false` | no |
| <a name="input_availability_zones"></a> [availability\_zones](#input\_availability\_zones) | List of availability zones for instance placement (optional, distributes instances if provided) | `list(string)` | `null` | no |
| <a name="input_backup_retention_period"></a> [backup\_retention\_period](#input\_backup\_retention\_period) | Backup retention period in days | `number` | `7` | no |
| <a name="input_cluster_identifier"></a> [cluster\_identifier](#input\_cluster\_identifier) | Unique identifier for the Aurora cluster | `string` | n/a | yes |
| <a name="input_database_name"></a> [database\_name](#input\_database\_name) | Name of the default database to create | `string` | n/a | yes |
| <a name="input_db_cluster_parameter_group_name"></a> [db\_cluster\_parameter\_group\_name](#input\_db\_cluster\_parameter\_group\_name) | Name of the DB cluster parameter group to associate | `string` | `null` | no |
| <a name="input_db_parameter_group_name"></a> [db\_parameter\_group\_name](#input\_db\_parameter\_group\_name) | Name of the DB parameter group to associate with instances | `string` | `null` | no |
| <a name="input_db_subnet_group_subnet_ids"></a> [db\_subnet\_group\_subnet\_ids](#input\_db\_subnet\_group\_subnet\_ids) | List of subnet IDs for the DB subnet group | `list(string)` | n/a | yes |
| <a name="input_deletion_protection"></a> [deletion\_protection](#input\_deletion\_protection) | Enable deletion protection for the cluster | `bool` | `true` | no |
| <a name="input_enabled_cloudwatch_logs_exports"></a> [enabled\_cloudwatch\_logs\_exports](#input\_enabled\_cloudwatch\_logs\_exports) | List of log types to export to CloudWatch (postgresql) | `list(string)` | <pre>[<br/>  "postgresql"<br/>]</pre> | no |
| <a name="input_engine_mode"></a> [engine\_mode](#input\_engine\_mode) | Engine mode for Aurora cluster (provisioned or serverless) | `string` | `"provisioned"` | no |
| <a name="input_engine_version"></a> [engine\_version](#input\_engine\_version) | Aurora PostgreSQL engine version | `string` | n/a | yes |
| <a name="input_global_cluster_identifier"></a> [global\_cluster\_identifier](#input\_global\_cluster\_identifier) | Global database identifier for multi-region deployments | `string` | `null` | no |
| <a name="input_iam_database_authentication_enabled"></a> [iam\_database\_authentication\_enabled](#input\_iam\_database\_authentication\_enabled) | Enable IAM database authentication | `bool` | `true` | no |
| <a name="input_instance_class"></a> [instance\_class](#input\_instance\_class) | Instance class for cluster instances | `string` | n/a | yes |
| <a name="input_instance_count"></a> [instance\_count](#input\_instance\_count) | Number of cluster instances to create (1 writer + N readers) | `number` | `2` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS key ID for storage encryption (uses AWS managed key if not specified) | `string` | `null` | no |
| <a name="input_master_password"></a> [master\_password](#input\_master\_password) | Master password for the database | `string` | n/a | yes |
| <a name="input_master_username"></a> [master\_username](#input\_master\_username) | Master username for the database | `string` | n/a | yes |
| <a name="input_monitoring_interval"></a> [monitoring\_interval](#input\_monitoring\_interval) | Enhanced monitoring interval in seconds (0, 1, 5, 10, 15, 30, 60) | `number` | `60` | no |
| <a name="input_monitoring_role_arn"></a> [monitoring\_role\_arn](#input\_monitoring\_role\_arn) | IAM role ARN for enhanced monitoring | `string` | `null` | no |
| <a name="input_performance_insights_enabled"></a> [performance\_insights\_enabled](#input\_performance\_insights\_enabled) | Enable Performance Insights | `bool` | `true` | no |
| <a name="input_performance_insights_kms_key_id"></a> [performance\_insights\_kms\_key\_id](#input\_performance\_insights\_kms\_key\_id) | KMS key ID for Performance Insights encryption | `string` | `null` | no |
| <a name="input_performance_insights_retention_period"></a> [performance\_insights\_retention\_period](#input\_performance\_insights\_retention\_period) | Performance Insights retention period in days | `number` | `7` | no |
| <a name="input_port"></a> [port](#input\_port) | Database port | `number` | `5432` | no |
| <a name="input_preferred_backup_window"></a> [preferred\_backup\_window](#input\_preferred\_backup\_window) | Preferred backup window (format: hh24:mi-hh24:mi) | `string` | `"03:00-04:00"` | no |
| <a name="input_preferred_maintenance_window"></a> [preferred\_maintenance\_window](#input\_preferred\_maintenance\_window) | Preferred maintenance window (format: ddd:hh24:mi-ddd:hh24:mi) | `string` | `"sun:04:00-sun:05:00"` | no |
| <a name="input_publicly_accessible"></a> [publicly\_accessible](#input\_publicly\_accessible) | Make cluster instances publicly accessible | `bool` | `false` | no |
| <a name="input_serverlessv2_scaling_configuration"></a> [serverlessv2\_scaling\_configuration](#input\_serverlessv2\_scaling\_configuration) | Serverless v2 scaling configuration (min and max capacity in ACUs) | <pre>object({<br/>    min_capacity = number<br/>    max_capacity = number<br/>  })</pre> | `null` | no |
| <a name="input_skip_final_snapshot"></a> [skip\_final\_snapshot](#input\_skip\_final\_snapshot) | Skip final snapshot on cluster deletion | `bool` | `false` | no |
| <a name="input_storage_encrypted"></a> [storage\_encrypted](#input\_storage\_encrypted) | Enable storage encryption | `bool` | `true` | no |
| <a name="input_storage_type"></a> [storage\_type](#input\_storage\_type) | Storage type (aurora or aurora-iopt1 for I/O optimized) | `string` | `"aurora"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | List of VPC security group IDs to associate with the cluster | `list(string)` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | Aurora cluster ARN |
| <a name="output_cluster_database_name"></a> [cluster\_database\_name](#output\_cluster\_database\_name) | Name of the default database |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Writer endpoint for the cluster (read-write) |
| <a name="output_cluster_engine_version"></a> [cluster\_engine\_version](#output\_cluster\_engine\_version) | Actual engine version running on the cluster |
| <a name="output_cluster_hosted_zone_id"></a> [cluster\_hosted\_zone\_id](#output\_cluster\_hosted\_zone\_id) | Route 53 hosted zone ID for the cluster endpoint |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | Aurora cluster ID |
| <a name="output_cluster_master_username"></a> [cluster\_master\_username](#output\_cluster\_master\_username) | Master username for the cluster |
| <a name="output_cluster_port"></a> [cluster\_port](#output\_cluster\_port) | Database port |
| <a name="output_cluster_reader_endpoint"></a> [cluster\_reader\_endpoint](#output\_cluster\_reader\_endpoint) | Reader endpoint for the cluster (read-only, load-balanced) |
| <a name="output_cluster_resource_id"></a> [cluster\_resource\_id](#output\_cluster\_resource\_id) | Cluster resource ID |
| <a name="output_connection_string_reader"></a> [connection\_string\_reader](#output\_connection\_string\_reader) | PostgreSQL connection string for reader endpoint (password not included) |
| <a name="output_connection_string_writer"></a> [connection\_string\_writer](#output\_connection\_string\_writer) | PostgreSQL connection string for writer endpoint (password not included) |
| <a name="output_db_subnet_group_arn"></a> [db\_subnet\_group\_arn](#output\_db\_subnet\_group\_arn) | ARN of the DB subnet group |
| <a name="output_db_subnet_group_name"></a> [db\_subnet\_group\_name](#output\_db\_subnet\_group\_name) | Name of the DB subnet group |
| <a name="output_instance_arns"></a> [instance\_arns](#output\_instance\_arns) | List of cluster instance ARNs |
| <a name="output_instance_availability_zones"></a> [instance\_availability\_zones](#output\_instance\_availability\_zones) | List of availability zones for cluster instances |
| <a name="output_instance_endpoints"></a> [instance\_endpoints](#output\_instance\_endpoints) | List of cluster instance endpoints |
| <a name="output_instance_ids"></a> [instance\_ids](#output\_instance\_ids) | List of cluster instance IDs |
| <a name="output_reader_instance_endpoints"></a> [reader\_instance\_endpoints](#output\_reader\_instance\_endpoints) | List of reader instance endpoints (all instances except first) |
| <a name="output_reader_instance_ids"></a> [reader\_instance\_ids](#output\_reader\_instance\_ids) | List of reader instance IDs (all instances except first) |
| <a name="output_writer_instance_endpoint"></a> [writer\_instance\_endpoint](#output\_writer\_instance\_endpoint) | Endpoint of the writer instance |
| <a name="output_writer_instance_id"></a> [writer\_instance\_id](#output\_writer\_instance\_id) | ID of the writer instance (first instance) |
<!-- END_TF_DOCS -->