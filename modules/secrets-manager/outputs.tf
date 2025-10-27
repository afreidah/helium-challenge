# -----------------------------------------------------------------------------
# SECRETS MANAGER MODULE OUTPUTS
# -----------------------------------------------------------------------------

output "secret_arns" {
  description = "Map of secret ARNs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.arn }
}

output "secret_ids" {
  description = "Map of secret IDs"
  value       = { for k, v in aws_secretsmanager_secret.this : k => v.id }
}

output "secret_versions" {
  description = "Map of secret version IDs"
  value       = { for k, v in aws_secretsmanager_secret_version.this : k => v.version_id }
}

output "read_policy_arn" {
  description = "ARN of the IAM read policy (if created)"
  value       = try(aws_iam_policy.read_secrets[0].arn, null)
}

output "read_policy_name" {
  description = "Name of the IAM read policy (if created)"
  value       = try(aws_iam_policy.read_secrets[0].name, null)
}
