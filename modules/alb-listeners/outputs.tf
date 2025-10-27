# -----------------------------------------------------------------------------
# ALB LISTENERS OUTPUTS
# -----------------------------------------------------------------------------

output "http_listener_arn" {
  description = "ARN of the HTTP listener"
  value       = length(aws_lb_listener.http) > 0 ? aws_lb_listener.http[0].arn : null
}

output "https_listener_arn" {
  description = "ARN of the HTTPS listener"
  value       = length(aws_lb_listener.https) > 0 ? aws_lb_listener.https[0].arn : null
}

output "listener_rule_arns" {
  description = "Map of listener rule names to their ARNs"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.arn }
}

output "listener_rule_ids" {
  description = "Map of listener rule names to their IDs"
  value       = { for k, v in aws_lb_listener_rule.this : k => v.id }
}
