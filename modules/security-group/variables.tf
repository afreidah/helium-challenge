# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "vpc_id" {
  description = "ID of the VPC where security group will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-z0-9]{8,}$", var.vpc_id))
    error_message = "VPC ID must be a valid format (vpc-xxxxxxxx)."
  }
}

variable "environment" {
  description = "Environment name (e.g., production, staging, development)"
  type        = string

  validation {
    condition     = can(regex("^(production|staging|development|prod|stage|dev)$", var.environment))
    error_message = "Environment must be one of: production, staging, development, prod, stage, dev."
  }
}

variable "region" {
  description = "AWS region where resources will be created"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]{1}$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1, eu-west-2)."
  }
}

variable "security_group_rules" {
  description = "Security group rule configuration from root.hcl containing name, description, and ingress/egress rules"
  type = object({
    name_suffix = string
    description = string
    ingress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
    egress_rules = list(object({
      from_port   = number
      to_port     = number
      protocol    = string
      cidr_blocks = list(string)
      description = string
    }))
  })

  validation {
    condition     = length(var.security_group_rules.name_suffix) > 0 && length(var.security_group_rules.name_suffix) <= 50
    error_message = "Security group name_suffix must be between 1 and 50 characters."
  }

  validation {
    condition     = length(var.security_group_rules.description) > 0 && length(var.security_group_rules.description) <= 255
    error_message = "Security group description must be between 1 and 255 characters."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.ingress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535
    ])
    error_message = "Ingress rule from_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.ingress_rules :
      rule.to_port >= 0 && rule.to_port <= 65535
    ])
    error_message = "Ingress rule to_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.ingress_rules :
      rule.from_port <= rule.to_port
    ])
    error_message = "Ingress rule from_port must be less than or equal to to_port."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.ingress_rules :
      contains(["tcp", "udp", "icmp", "icmpv6", "all", "-1"], rule.protocol)
    ])
    error_message = "Ingress rule protocol must be one of: tcp, udp, icmp, icmpv6, all, -1."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.ingress_rules :
      length(rule.cidr_blocks) > 0
    ])
    error_message = "Ingress rule must have at least one CIDR block."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.ingress_rules :
      alltrue([
        for cidr in rule.cidr_blocks :
        can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "Ingress rule CIDR blocks must be valid CIDR notation."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.egress_rules :
      rule.from_port >= 0 && rule.from_port <= 65535
    ])
    error_message = "Egress rule from_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.egress_rules :
      rule.to_port >= 0 && rule.to_port <= 65535
    ])
    error_message = "Egress rule to_port must be between 0 and 65535."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.egress_rules :
      rule.from_port <= rule.to_port
    ])
    error_message = "Egress rule from_port must be less than or equal to to_port."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.egress_rules :
      contains(["tcp", "udp", "icmp", "icmpv6", "all", "-1"], rule.protocol)
    ])
    error_message = "Egress rule protocol must be one of: tcp, udp, icmp, icmpv6, all, -1."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.egress_rules :
      length(rule.cidr_blocks) > 0
    ])
    error_message = "Egress rule must have at least one CIDR block."
  }

  validation {
    condition = alltrue([
      for rule in var.security_group_rules.egress_rules :
      alltrue([
        for cidr in rule.cidr_blocks :
        can(cidrhost(cidr, 0))
      ])
    ])
    error_message = "Egress rule CIDR blocks must be valid CIDR notation."
  }
}

# -----------------------------------------------------------------------------
# OPTIONAL VARIABLES
# -----------------------------------------------------------------------------

variable "tags" {
  description = "A map of tags to add to all resources"
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
