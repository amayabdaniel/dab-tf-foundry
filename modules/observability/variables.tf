variable "service_name" {
  description = "Name of the service to observe."
  type        = string
}

variable "environment" {
  description = "Deployment environment."
  type        = string

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "environment must be one of: dev, staging, prod."
  }
}

variable "service_type" {
  description = "Type of service: container, function, or worker."
  type        = string

  validation {
    condition     = contains(["container", "function", "worker"], var.service_type)
    error_message = "service_type must be one of: container, function, worker."
  }
}

# -- CloudWatch Log Group --

variable "log_group_name" {
  description = "CloudWatch log group name to attach metric filters to."
  type        = string
}

# -- ECS inputs (used when service_type is container or worker) --

variable "ecs_cluster_name" {
  description = "ECS cluster name. Required for container/worker dashboards."
  type        = string
  default     = null
}

variable "ecs_service_name" {
  description = "ECS service name. Required for container/worker dashboards."
  type        = string
  default     = null
}

# -- Lambda inputs (used when service_type is function) --

variable "lambda_function_name" {
  description = "Lambda function name. Required for function dashboards."
  type        = string
  default     = null
}

# -- Queue inputs (optional, for services that consume queues) --

variable "sqs_queue_name" {
  description = "SQS queue name to include in dashboard. Leave null to omit."
  type        = string
  default     = null
}

variable "dlq_queue_name" {
  description = "DLQ name to include in dashboard. Leave null to omit."
  type        = string
  default     = null
}

# -- Database inputs (optional, for services with a database) --

variable "db_instance_identifier" {
  description = "RDS DB instance identifier to include in dashboard. Leave null to omit."
  type        = string
  default     = null
}

# -- Alarms --

variable "alarm_arns" {
  description = "List of existing alarm ARNs to aggregate into a composite alarm."
  type        = list(string)
  default     = []
}

variable "alarm_actions" {
  description = "SNS topic ARNs to notify on composite alarm."
  type        = list(string)
  default     = []
}

# -- Error patterns --

variable "error_log_pattern" {
  description = "CloudWatch metric filter pattern for errors in logs."
  type        = string
  default     = "ERROR"
}

variable "error_threshold" {
  description = "Number of log errors per period before alarm triggers."
  type        = number
  default     = 5
}

variable "tags" {
  description = "Additional tags to merge with standard tags."
  type        = map(string)
  default     = {}
}
