# -----------------------------------------------------------------------------
# ALB TARGET GROUPS OUTPUTS
# -----------------------------------------------------------------------------

output "target_group_arns" {
  description = "Map of target group names to their ARNs"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn }
}

output "target_group_arn_suffixes" {
  description = "Map of target group names to their ARN suffixes for CloudWatch metrics"
  value       = { for k, v in aws_lb_target_group.this : k => v.arn_suffix }
}

output "target_group_names" {
  description = "Map of target group keys to their actual names"
  value       = { for k, v in aws_lb_target_group.this : k => v.name }
}

output "target_group_ids" {
  description = "Map of target group names to their IDs"
  value       = { for k, v in aws_lb_target_group.this : k => v.id }
}
