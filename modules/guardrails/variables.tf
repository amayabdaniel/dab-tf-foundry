variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "required_tag_keys" {
  description = "Tag keys that must be present on all resources. Enforced via AWS Config."
  type        = list(string)
  default     = ["Service", "Environment", "ManagedBy"]
}

variable "allowed_instance_types" {
  description = "Allowed RDS instance types. Prevents over-provisioning."
  type        = list(string)
  default = [
    "db.t4g.micro",
    "db.t4g.small",
    "db.t4g.medium",
    "db.t4g.large",
    "db.r6g.large",
    "db.r6g.xlarge",
  ]
}

variable "max_log_retention_days" {
  description = "Maximum CloudWatch log retention in days. Prevents unbounded log costs."
  type        = number
  default     = 90
}

variable "alarm_actions" {
  description = "SNS topic ARNs to notify when guardrail violations are detected."
  type        = list(string)
  default     = []
}

variable "enable_config_rules" {
  description = "Whether to create AWS Config rules. Requires AWS Config recorder to be enabled."
  type        = bool
  default     = true
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
