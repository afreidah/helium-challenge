# -----------------------------------------------------------------------------
# APPLICATION LOAD BALANCER OUTPUTS
# -----------------------------------------------------------------------------

output "alb_id" {
  description = "ID of the Application Load Balancer"
  value       = aws_lb.this.id
}

output "alb_arn" {
  description = "ARN of the Application Load Balancer"
  value       = aws_lb.this.arn
}

output "alb_arn_suffix" {
  description = "ARN suffix for use with CloudWatch metrics"
  value       = aws_lb.this.arn_suffix
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.this.dns_name
}

output "alb_zone_id" {
  description = "Route53 zone ID for the Application Load Balancer"
  value       = aws_lb.this.zone_id
}

output "alb_name" {
  description = "Name of the Application Load Balancer"
  value       = aws_lb.this.name
}
