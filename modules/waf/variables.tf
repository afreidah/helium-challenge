# -----------------------------------------------------------------------------
# WAF MODULE VARIABLES
# -----------------------------------------------------------------------------
#
# This file defines input variables for the AWS WAF WebACL module,
# including basic configuration, managed rule settings, rate limiting,
# geographic blocking, logging configuration, and observability options.
#
# Variable Categories:
#   - Basic Configuration: Name, scope, and default action
#   - Managed Rule Configuration: AWS managed rule groups
#   - Rate Limiting: Request throttling per IP
#   - Geographic Blocking: Country-based access control
#   - Logging Configuration: CloudWatch logging settings
#   - Observability: Metrics and request sampling
#   - Tagging: Resource tags for organization
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# BASIC CONFIGURATION
# -----------------------------------------------------------------------------

variable "name" {
  description = "Name of the WAF WebACL"
  type        = string

  validation {
    condition     = can(regex("^[a-zA-Z0-9-_]+$", var.name))
    error_message = "WAF name must contain only alphanumeric characters, hyphens, and underscores."
  }

  validation {
    condition     = length(var.name) >= 1 && length(var.name) <= 128
    error_message = "WAF name must be between 1 and 128 characters."
  }
}

variable "scope" {
  description = "Scope of the WAF (REGIONAL for ALB/API Gateway, CLOUDFRONT for CloudFront)"
  type        = string
  default     = "REGIONAL"

  validation {
    condition     = contains(["REGIONAL", "CLOUDFRONT"], var.scope)
    error_message = "Scope must be either REGIONAL or CLOUDFRONT."
  }
}

variable "default_action" {
  description = "Default action for requests that do not match any rules (allow or block)"
  type        = string
  default     = "allow"

  validation {
    condition     = contains(["allow", "block"], var.default_action)
    error_message = "Default action must be either 'allow' or 'block'."
  }
}

# -----------------------------------------------------------------------------
# MANAGED RULE CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_aws_managed_rules" {
  description = "Enable AWS managed rule groups for common vulnerabilities and bad inputs"
  type        = bool
  default     = true
}

variable "enable_ip_reputation" {
  description = "Enable AWS IP reputation lists to block known malicious sources"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# RATE LIMITING CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_rate_limiting" {
  description = "Enable rate limiting to prevent request flooding"
  type        = bool
  default     = true
}

variable "rate_limit" {
  description = "Maximum number of requests allowed per 5 minutes from a single IP"
  type        = number
  default     = 2000

  validation {
    condition     = var.rate_limit >= 100 && var.rate_limit <= 20000000
    error_message = "Rate limit must be between 100 and 20,000,000 requests per 5 minutes."
  }
}

# -----------------------------------------------------------------------------
# GEOGRAPHIC BLOCKING CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_geo_blocking" {
  description = "Enable geographic blocking based on country codes"
  type        = bool
  default     = false
}

variable "blocked_countries" {
  description = "List of country codes to block using ISO 3166-1 alpha-2 format"
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for country in var.blocked_countries : can(regex("^[A-Z]{2}$", country))])
    error_message = "Country codes must be in ISO 3166-1 alpha-2 format (two uppercase letters)."
  }

  validation {
    condition     = length(var.blocked_countries) <= 250
    error_message = "Maximum of 250 country codes are allowed."
  }
}

# -----------------------------------------------------------------------------
# LOGGING CONFIGURATION
# -----------------------------------------------------------------------------

variable "enable_logging" {
  description = "Enable WAF logging to CloudWatch"
  type        = bool
  default     = true
}

variable "log_retention_days" {
  description = "Number of days to retain WAF logs"
  type        = number
  default     = 90

  validation {
    condition = contains([
      0, 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.log_retention_days)
    error_message = "Log retention days must be one of the valid CloudWatch Logs retention periods: 0 (never expire), 1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653 days."
  }
}

variable "log_kms_key_id" {
  description = "KMS key ID for encrypting WAF logs"
  type        = string
  default     = null

  validation {
    condition     = var.log_kms_key_id == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.log_kms_key_id))
    error_message = "KMS key ID must be a valid KMS key ARN in the format: arn:aws:kms:region:account-id:key/key-id"
  }
}

variable "redacted_fields" {
  description = "List of header names to redact from logs (e.g., authorization, cookie)"
  type        = list(string)
  default     = ["authorization", "cookie"]

  validation {
    condition     = alltrue([for field in var.redacted_fields : can(regex("^[a-zA-Z0-9_-]+$", field))])
    error_message = "Redacted field names must contain only alphanumeric characters, hyphens, and underscores."
  }

  validation {
    condition     = length(var.redacted_fields) <= 100
    error_message = "Maximum of 100 redacted fields are allowed."
  }
}

# -----------------------------------------------------------------------------
# OBSERVABILITY CONFIGURATION
# -----------------------------------------------------------------------------

variable "cloudwatch_metrics_enabled" {
  description = "Enable CloudWatch metrics for monitoring WAF activity"
  type        = bool
  default     = true
}

variable "sampled_requests_enabled" {
  description = "Enable sampling of requests for analysis and troubleshooting"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# TAGGING
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to the WAF WebACL"
  type        = map(string)
  default     = {}
}
