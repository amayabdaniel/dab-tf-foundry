variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
}

variable "reserved_concurrent_executions" {
  description = "Reserved concurrency for the Lambda function."
  type        = number
  default     = 50
}
