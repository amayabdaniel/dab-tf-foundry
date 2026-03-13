variable "environment" {
  description = "Deployment environment."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID from the shared platform."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "ecs_cluster_arn" {
  description = "ARN of the shared ECS cluster."
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
}

variable "container_image" {
  description = "Docker image URI for the manufacturing-orchestrator."
  type        = string
}

variable "cpu" {
  description = "CPU units for the ECS task."
  type        = number
  default     = 512
}

variable "memory" {
  description = "Memory in MiB for the ECS task."
  type        = number
  default     = 1024
}
