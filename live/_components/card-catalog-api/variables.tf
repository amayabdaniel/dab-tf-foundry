variable "environment" {
  description = "Deployment environment."
  type        = string
}

# -- Shared platform inputs (provided by foundation stack outputs) --

variable "vpc_id" {
  description = "VPC ID from the shared platform."
  type        = string
}

variable "private_subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "data_subnet_ids" {
  description = "Data-tier subnet IDs for RDS."
  type        = list(string)
}

variable "ecs_cluster_arn" {
  description = "ARN of the shared ECS cluster."
  type        = string
}

variable "alb_listener_arn" {
  description = "ARN of the shared ALB HTTPS listener."
  type        = string
}

variable "alb_security_group_id" {
  description = "Security group ID of the shared ALB. Passed to the container module so the task SG accepts traffic only from the ALB SG, not 0.0.0.0/0."
  type        = string
}

variable "alarm_sns_topic_arn" {
  description = "SNS topic ARN for CloudWatch alarm notifications."
  type        = string
}

# -- Service-specific inputs --

variable "container_image" {
  description = "Docker image URI for the card-catalog-api."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
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

variable "db_instance_class" {
  description = "RDS instance class."
  type        = string
  default     = "db.t4g.small"
}

variable "db_multi_az" {
  description = "Enable Multi-AZ for the database."
  type        = bool
  default     = false
}
