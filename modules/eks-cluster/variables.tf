# -----------------------------------------------------------------------------
# EKS CLUSTER MODULE - INPUT VARIABLES
# -----------------------------------------------------------------------------
#
# This file defines all configurable parameters for the EKS cluster module,
# including cluster configuration, networking, security, logging, add-ons,
# and IAM authentication settings.
#
# Variable Categories:
#   - Required Variables: Essential parameters with no defaults
#   - Cluster Configuration: Kubernetes version and basic settings
#   - Network Configuration: VPC, subnets, and API endpoint access
#   - Security & Encryption: KMS keys and security groups
#   - Logging: CloudWatch log configuration
#   - Add-ons: EKS managed add-on versions
#   - Authentication: IAM access configuration
#   - Node Groups: Default node group configuration
#   - Tagging: Resource tags for organization
# -----------------------------------------------------------------------------

# -----------------------------------------------------------------------------
# REQUIRED VARIABLES
# -----------------------------------------------------------------------------

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string

  validation {
    condition     = length(var.cluster_name) > 0 && length(var.cluster_name) <= 100
    error_message = "Cluster name must be between 1 and 100 characters."
  }

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.cluster_name))
    error_message = "Cluster name must start and end with alphanumeric characters and can only contain alphanumerics and hyphens."
  }
}

variable "vpc_id" {
  description = "VPC ID where the cluster will be created"
  type        = string

  validation {
    condition     = can(regex("^vpc-[a-f0-9]+$", var.vpc_id))
    error_message = "VPC ID must be a valid format (vpc-xxxxxxxx)."
  }
}

variable "subnet_ids" {
  description = "List of subnet IDs for the EKS cluster (should be private subnets)"
  type        = list(string)

  validation {
    condition     = length(var.subnet_ids) >= 2
    error_message = "At least 2 subnet IDs are required for high availability."
  }

  validation {
    condition = alltrue([
      for subnet_id in var.subnet_ids :
      can(regex("^subnet-[a-f0-9]+$", subnet_id))
    ])
    error_message = "All subnet IDs must be in valid format (subnet-xxxxxxxx)."
  }
}

variable "cluster_encryption_key_arn" {
  description = "ARN of KMS key for cluster encryption"
  type        = string

  validation {
    condition     = can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.cluster_encryption_key_arn))
    error_message = "Cluster encryption key ARN must be a valid KMS key ARN."
  }
}

# -----------------------------------------------------------------------------
# CLUSTER CONFIGURATION
# -----------------------------------------------------------------------------

variable "kubernetes_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.31"

  validation {
    condition     = can(regex("^1\\.(2[89]|3[0-9])$", var.kubernetes_version))
    error_message = "Kubernetes version must be 1.28 or higher (format: 1.xx)."
  }
}

# -----------------------------------------------------------------------------
# NETWORK CONFIGURATION
# -----------------------------------------------------------------------------

variable "endpoint_private_access" {
  description = "Enable private API server endpoint"
  type        = bool
  default     = true
}

variable "endpoint_public_access" {
  description = "Enable public API server endpoint"
  type        = bool
  default     = true

  validation {
    condition     = var.endpoint_public_access == false || var.endpoint_private_access == true
    error_message = "Private access must be enabled if public access is disabled to maintain cluster connectivity."
  }
}

variable "public_access_cidrs" {
  description = "List of CIDR blocks that can access the public API endpoint"
  type        = list(string)
  default     = ["0.0.0.0/0"]

  validation {
    condition = alltrue([
      for cidr in var.public_access_cidrs :
      can(cidrhost(cidr, 0))
    ])
    error_message = "All public access CIDRs must be valid CIDR blocks."
  }

  validation {
    condition     = length(var.public_access_cidrs) <= 40
    error_message = "Maximum of 40 CIDR blocks allowed for public access."
  }
}

variable "node_security_group_id" {
  description = "Security group ID for EKS nodes (optional - for cluster-to-node communication)"
  type        = string
  default     = null

  validation {
    condition     = var.node_security_group_id == null || can(regex("^sg-[a-f0-9]{8,}$", var.node_security_group_id))
    error_message = "Node security group ID must be null or a valid format (sg-xxxxxxxx)."
  }
}

# -----------------------------------------------------------------------------
# SECURITY & ENCRYPTION CONFIGURATION
# -----------------------------------------------------------------------------

variable "eks_encryption_config" {
  description = "Encryption configuration for EKS cluster secrets using KMS"
  type = object({
    resources   = list(string)
    kms_key_arn = string
  })
  default = {
    resources   = ["secrets"]
    kms_key_arn = null
  }

  validation {
    condition     = contains(var.eks_encryption_config.resources, "secrets")
    error_message = "Encryption config must include 'secrets' in resources list."
  }

  validation {
    condition = (
      var.eks_encryption_config.kms_key_arn == null ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.eks_encryption_config.kms_key_arn))
    )
    error_message = "KMS key ARN must be null or a valid KMS key ARN format."
  }
}

# -----------------------------------------------------------------------------
# LOGGING CONFIGURATION
# -----------------------------------------------------------------------------

variable "enabled_cluster_log_types" {
  description = "List of control plane logging types to enable"
  type        = list(string)
  default     = ["api", "audit", "authenticator", "controllerManager", "scheduler"]

  validation {
    condition = alltrue([
      for log_type in var.enabled_cluster_log_types :
      contains(["api", "audit", "authenticator", "controllerManager", "scheduler"], log_type)
    ])
    error_message = "Enabled log types must be one of: api, audit, authenticator, controllerManager, scheduler."
  }

  validation {
    condition     = length(var.enabled_cluster_log_types) == length(distinct(var.enabled_cluster_log_types))
    error_message = "Enabled log types must not contain duplicates."
  }
}

variable "cloudwatch_retention_days" {
  description = "Number of days to retain CloudWatch logs"
  type        = number
  default     = 90

  validation {
    condition = contains([
      1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180,
      365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, 3653
    ], var.cloudwatch_retention_days)
    error_message = "CloudWatch retention days must be a valid value (1, 3, 5, 7, 14, 30, 60, 90, 120, 150, 180, 365, 400, 545, 731, 1096, 1827, 2192, 2557, 2922, 3288, or 3653)."
  }
}

variable "cloudwatch_kms_key_id" {
  description = "KMS key ID for CloudWatch log encryption"
  type        = string
  default     = null

  validation {
    condition = (
      var.cloudwatch_kms_key_id == null ||
      can(regex("^[a-f0-9]{8}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{4}-[a-f0-9]{12}$", var.cloudwatch_kms_key_id)) ||
      can(regex("^arn:aws:kms:[a-z0-9-]+:[0-9]{12}:key/[a-f0-9-]+$", var.cloudwatch_kms_key_id)) ||
      can(regex("^alias/[a-zA-Z0-9/_-]+$", var.cloudwatch_kms_key_id))
    )
    error_message = "CloudWatch KMS key ID must be null, a valid KMS key ID, ARN, or alias."
  }
}

variable "eks_enable_cluster_logging" {
  description = "Enable cluster control plane logging to CloudWatch"
  type        = bool
  default     = true
}

# -----------------------------------------------------------------------------
# EKS ADD-ON VERSIONS
# -----------------------------------------------------------------------------

variable "vpc_cni_version" {
  description = "Version of VPC CNI add-on"
  type        = string
  default     = null # Uses latest if not specified

  validation {
    condition = (
      var.vpc_cni_version == null ||
      can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+-eksbuild\\.[0-9]+$", var.vpc_cni_version))
    )
    error_message = "VPC CNI version must be null or in format: vX.Y.Z-eksbuild.N"
  }
}

variable "coredns_version" {
  description = "Version of CoreDNS add-on"
  type        = string
  default     = null

  validation {
    condition = (
      var.coredns_version == null ||
      can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+-eksbuild\\.[0-9]+$", var.coredns_version))
    )
    error_message = "CoreDNS version must be null or in format: vX.Y.Z-eksbuild.N"
  }
}

variable "kube_proxy_version" {
  description = "Version of kube-proxy add-on"
  type        = string
  default     = null

  validation {
    condition = (
      var.kube_proxy_version == null ||
      can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+-eksbuild\\.[0-9]+$", var.kube_proxy_version))
    )
    error_message = "Kube-proxy version must be null or in format: vX.Y.Z-eksbuild.N"
  }
}

variable "eks_enable_pod_identity_agent" {
  description = "Enable EKS Pod Identity Agent add-on (recommended over IRSA)"
  type        = bool
  default     = true
}

variable "eks_pod_identity_agent_version" {
  description = "Version of Pod Identity Agent add-on (null = latest compatible version)"
  type        = string
  default     = null

  validation {
    condition = (
      var.eks_pod_identity_agent_version == null ||
      can(regex("^v[0-9]+\\.[0-9]+\\.[0-9]+-eksbuild\\.[0-9]+$", var.eks_pod_identity_agent_version))
    )
    error_message = "Pod Identity Agent version must be null or in format: vX.Y.Z-eksbuild.N"
  }
}

# -----------------------------------------------------------------------------
# AUTHENTICATION & ACCESS CONFIGURATION
# -----------------------------------------------------------------------------

variable "eks_authentication_mode" {
  description = "Authentication mode for cluster access (API or API_AND_CONFIG_MAP)"
  type        = string
  default     = "API_AND_CONFIG_MAP"

  validation {
    condition     = contains(["API", "API_AND_CONFIG_MAP"], var.eks_authentication_mode)
    error_message = "Authentication mode must be either 'API' or 'API_AND_CONFIG_MAP'."
  }
}

variable "eks_bootstrap_cluster_creator_admin_permissions" {
  description = "Bootstrap cluster creator admin permissions (grants admin access to IAM principal creating the cluster)"
  type        = bool
  default     = true
}

variable "manage_aws_auth_configmap" {
  description = "Whether to manage the aws-auth ConfigMap"
  type        = bool
  default     = true
}

variable "node_iam_role_arn" {
  description = "IAM role ARN for EKS nodes (required if manage_aws_auth_configmap is true)"
  type        = string
  default     = null

  validation {
    condition = (
      var.node_iam_role_arn == null ||
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", var.node_iam_role_arn))
    )
    error_message = "Node IAM role ARN must be null or a valid IAM role ARN."
  }
}

variable "aws_auth_roles" {
  description = "Additional IAM roles to add to aws-auth ConfigMap"
  type = list(object({
    rolearn  = string
    username = string
    groups   = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for role in var.aws_auth_roles :
      can(regex("^arn:aws:iam::[0-9]{12}:role/.+$", role.rolearn))
    ])
    error_message = "All role ARNs must be valid IAM role ARN format."
  }

  validation {
    condition = alltrue([
      for role in var.aws_auth_roles :
      length(role.username) > 0 && length(role.username) <= 255
    ])
    error_message = "All role usernames must be between 1 and 255 characters."
  }
}

variable "aws_auth_users" {
  description = "Additional IAM users to add to aws-auth ConfigMap"
  type = list(object({
    userarn  = string
    username = string
    groups   = list(string)
  }))
  default = []

  validation {
    condition = alltrue([
      for user in var.aws_auth_users :
      can(regex("^arn:aws:iam::[0-9]{12}:user/.+$", user.userarn))
    ])
    error_message = "All user ARNs must be valid IAM user ARN format."
  }

  validation {
    condition = alltrue([
      for user in var.aws_auth_users :
      length(user.username) > 0 && length(user.username) <= 255
    ])
    error_message = "All user usernames must be between 1 and 255 characters."
  }
}

# -----------------------------------------------------------------------------
# NODE GROUP CONFIGURATION
# -----------------------------------------------------------------------------

variable "eks_node_groups_defaults" {
  description = "Default configuration for all EKS node groups"
  type = object({
    instance_types             = list(string)
    desired_size               = number
    min_size                   = number
    max_size                   = number
    disk_size                  = number
    disk_type                  = string
    disk_encrypted             = bool
    enable_bootstrap_user_data = bool
    metadata_options           = map(string)
    force_update_version       = bool
    update_config              = map(number)
    tags                       = map(string)
  })
  default = {
    instance_types             = ["t3.medium"]
    desired_size               = 2
    min_size                   = 1
    max_size                   = 5
    disk_size                  = 50
    disk_type                  = "gp3"
    disk_encrypted             = true
    enable_bootstrap_user_data = false
    metadata_options = {
      http_endpoint               = "enabled"
      http_tokens                 = "required"
      http_put_response_hop_limit = "1"
      instance_metadata_tags      = "disabled"
    }
    force_update_version = false
    update_config = {
      max_unavailable_percentage = 33
    }
    tags = {}
  }

  validation {
    condition     = var.eks_node_groups_defaults.disk_encrypted == true
    error_message = "Node group disk encryption must be enabled for security compliance."
  }

  validation {
    condition     = var.eks_node_groups_defaults.metadata_options["http_tokens"] == "required"
    error_message = "IMDSv2 must be required (http_tokens = 'required') for security compliance."
  }

  validation {
    condition     = contains(["gp2", "gp3", "io1", "io2"], var.eks_node_groups_defaults.disk_type)
    error_message = "Disk type must be one of: gp2, gp3, io1, io2."
  }

  validation {
    condition     = var.eks_node_groups_defaults.min_size <= var.eks_node_groups_defaults.desired_size && var.eks_node_groups_defaults.desired_size <= var.eks_node_groups_defaults.max_size
    error_message = "Node group sizing must satisfy: min_size <= desired_size <= max_size."
  }

  validation {
    condition     = var.eks_node_groups_defaults.min_size >= 0 && var.eks_node_groups_defaults.max_size <= 1000
    error_message = "Node group min_size must be >= 0 and max_size must be <= 1000."
  }

  validation {
    condition     = var.eks_node_groups_defaults.disk_size >= 20 && var.eks_node_groups_defaults.disk_size <= 16384
    error_message = "Disk size must be between 20 and 16384 GB."
  }

  validation {
    condition = (
      lookup(var.eks_node_groups_defaults.metadata_options, "http_endpoint", "enabled") == "enabled" ||
      lookup(var.eks_node_groups_defaults.metadata_options, "http_endpoint", "enabled") == "disabled"
    )
    error_message = "Metadata http_endpoint must be either 'enabled' or 'disabled'."
  }

  validation {
    condition = (
      tonumber(lookup(var.eks_node_groups_defaults.metadata_options, "http_put_response_hop_limit", "1")) >= 1 &&
      tonumber(lookup(var.eks_node_groups_defaults.metadata_options, "http_put_response_hop_limit", "1")) <= 64
    )
    error_message = "Metadata http_put_response_hop_limit must be between 1 and 64."
  }

  validation {
    condition = (
      lookup(var.eks_node_groups_defaults.update_config, "max_unavailable_percentage", 33) >= 1 &&
      lookup(var.eks_node_groups_defaults.update_config, "max_unavailable_percentage", 33) <= 100
    )
    error_message = "Update config max_unavailable_percentage must be between 1 and 100."
  }

  validation {
    condition     = length(var.eks_node_groups_defaults.instance_types) > 0
    error_message = "At least one instance type must be specified."
  }
}

# -----------------------------------------------------------------------------
# TAGGING
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}

  validation {
    condition     = length(var.tags) <= 50
    error_message = "Maximum of 50 tags allowed per resource."
  }
}
