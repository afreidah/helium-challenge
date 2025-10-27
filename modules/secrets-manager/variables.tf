# -----------------------------------------------------------------------------
# SECRETS MANAGER MODULE VARIABLES
# -----------------------------------------------------------------------------

variable "secrets" {
  description = "Map of secrets to create with keys as secret names and values containing secret configuration"
  type = map(object({
    description             = optional(string)
    secret_string           = string
    kms_key_id              = optional(string)
    recovery_window_in_days = optional(number, 30)
    rotation_lambda_arn     = optional(string)
    rotation_days           = optional(number, 30)
  }))
  default = {}

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      v.recovery_window_in_days >= 7 && v.recovery_window_in_days <= 30
    ])
    error_message = "Recovery window must be between 7 and 30 days."
  }

  validation {
    condition = alltrue([
      for k, v in var.secrets :
      v.rotation_days == null || (v.rotation_days >= 1 && v.rotation_days <= 1000)
    ])
    error_message = "Rotation days must be between 1 and 1000 days."
  }
}

# -----------------------------------------------------------------------------
# DEPENDENCY INJECTION VARIABLES
# -----------------------------------------------------------------------------
# These variables allow Terragrunt to inject values from dependencies
# without complex nested expressions that Terragrunt can't evaluate

variable "kms_key_id" {
  description = "KMS key ID to inject into all secrets (overrides individual kms_key_id values)"
  type        = string
  default     = null
}

variable "aurora_endpoint" {
  description = "Aurora cluster endpoint to inject into Aurora master credentials secret"
  type        = string
  default     = null
}

variable "aurora_reader_endpoint" {
  description = "Aurora cluster reader endpoint to inject into Aurora master credentials secret"
  type        = string
  default     = null
}

variable "aurora_port" {
  description = "Aurora cluster port to inject into Aurora master credentials secret"
  type        = number
  default     = null
}

variable "aurora_database_name" {
  description = "Aurora database name to inject into Aurora master credentials secret"
  type        = string
  default     = null
}

variable "create_read_policy" {
  description = "Create IAM policy for reading secrets"
  type        = bool
  default     = false
}

variable "policy_name_prefix" {
  description = "Prefix for IAM policy name"
  type        = string
  default     = "secretsmanager"

  validation {
    condition     = length(var.policy_name_prefix) > 0 && length(var.policy_name_prefix) <= 50
    error_message = "Policy name prefix must be between 1 and 50 characters."
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for encrypting secrets (used in IAM policy)"
  type        = string
  default     = "*"

  validation {
    condition     = var.kms_key_arn == "*" || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid KMS key ARN or '*'."
  }
}

variable "tags" {
  description = "Tags to apply to all secrets"
  type        = map(string)
  default     = {}

  validation {
    condition = alltrue([
      for key, value in var.tags :
      length(key) <= 128 && length(value) <= 256
    ])
    error_message = "Tag keys must be <= 128 characters and values must be <= 256 characters."
  }
}
