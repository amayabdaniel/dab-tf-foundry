variable "function_name" {
  description = "Name of the Lambda function."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,48}[a-z0-9]$", var.function_name))
    error_message = "function_name must be lowercase alphanumeric with hyphens, 3-50 characters."
  }
}

variable "environment" {
  description = "Deployment environment (e.g., dev, staging, prod)."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "filename" {
  description = "Path to the Lambda deployment package (ZIP file)."
  type        = string
}

variable "source_code_hash" {
  description = "Base64-encoded SHA256 hash of the deployment package."
  type        = string
}

variable "handler" {
  description = "Lambda function handler (e.g., handler.lambda_handler)."
  type        = string
  default     = "handler.lambda_handler"
}

variable "runtime" {
  description = "Lambda runtime identifier."
  type        = string
  default     = "python3.12"
}

variable "timeout" {
  description = "Function timeout in seconds."
  type        = number
  default     = 30

  validation {
    condition     = var.timeout >= 1 && var.timeout <= 900
    error_message = "timeout must be between 1 and 900 seconds."
  }
}

variable "memory_size" {
  description = "Function memory in MB."
  type        = number
  default     = 128

  validation {
    condition     = var.memory_size >= 128 && var.memory_size <= 10240
    error_message = "memory_size must be between 128 and 10240 MB."
  }
}

variable "environment_variables" {
  description = "Environment variables for the function."
  type        = map(string)
  default     = {}
}

variable "subnet_ids" {
  description = "Subnet IDs for VPC-attached Lambda. Leave empty for non-VPC."
  type        = list(string)
  default     = []
}

variable "security_group_ids" {
  description = "Security group IDs for VPC-attached Lambda. Leave empty for non-VPC."
  type        = list(string)
  default     = []
}

variable "sqs_event_source_arn" {
  description = "ARN of SQS queue to use as event source. Leave null to disable."
  type        = string
  default     = null
}

variable "batch_size" {
  description = "SQS event source mapping batch size."
  type        = number
  default     = 10
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for the function. -1 for unreserved."
  type        = number
  default     = -1
}

variable "additional_policy_statements" {
  description = "Additional IAM policy statements for the Lambda execution role."
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger."
  type        = list(string)
  default     = []
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}

variable "log_retention_days" {
  description = "CloudWatch log retention in days."
  type        = number
  default     = 30
}
