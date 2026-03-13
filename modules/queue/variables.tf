variable "queue_name" {
  description = "Base name of the SQS queue."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,58}[a-z0-9]$", var.queue_name))
    error_message = "queue_name must be lowercase alphanumeric with hyphens, 3-60 characters."
  }
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "visibility_timeout_seconds" {
  description = "Visibility timeout for the main queue in seconds."
  type        = number
  default     = 30
}

variable "message_retention_seconds" {
  description = "Message retention period in seconds. Default 4 days."
  type        = number
  default     = 345600
}

variable "max_receive_count" {
  description = "Number of receives before a message is sent to the DLQ."
  type        = number
  default     = 3
}

variable "dlq_message_retention_seconds" {
  description = "Message retention period for the DLQ in seconds. Default 14 days."
  type        = number
  default     = 1209600
}

variable "kms_master_key_id" {
  description = "KMS key ID for server-side encryption. Use 'alias/aws/sqs' for AWS-managed key."
  type        = string
  default     = "alias/aws/sqs"
}

variable "queue_policy" {
  description = "IAM policy document JSON for the queue. Leave null for no policy."
  type        = string
  default     = null
}

variable "alarm_actions" {
  description = "List of ARNs to notify when DLQ alarm triggers."
  type        = list(string)
  default     = []
}

variable "dlq_alarm_threshold" {
  description = "Number of visible messages in DLQ before alarm triggers."
  type        = number
  default     = 1
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
