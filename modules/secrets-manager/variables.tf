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
    rotation_days           = optional(number)
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
# IAM POLICY CONFIGURATION
# -----------------------------------------------------------------------------

variable "create_read_policy" {
  description = "Create IAM policy for reading secrets"
  type        = bool
  default     = false
}

variable "policy_name_prefix" {
  description = "Prefix for IAM policy name"
  type        = string
  default     = "app"

  validation {
    condition     = can(regex("^[a-zA-Z0-9+=,.@_-]+$", var.policy_name_prefix))
    error_message = "Policy name prefix must contain only alphanumeric characters and +=,.@_-"
  }
}

variable "kms_key_arn" {
  description = "KMS key ARN for IAM policy permissions (required if create_read_policy is true)"
  type        = string
  default     = null

  validation {
    condition     = var.kms_key_arn == null || can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.kms_key_arn))
    error_message = "KMS key ARN must be a valid KMS key ARN format."
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
