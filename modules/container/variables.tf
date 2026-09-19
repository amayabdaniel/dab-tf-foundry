variable "service_name" {
  description = "Name of the ECS service. Used for resource naming and tagging."
  type        = string

  validation {
    condition     = can(regex("^[a-z][a-z0-9-]{1,28}[a-z0-9]$", var.service_name))
    error_message = "service_name must be lowercase alphanumeric with hyphens, 3-30 characters."
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

variable "cluster_arn" {
  description = "ARN of the ECS cluster to deploy into."
  type        = string
}

variable "vpc_id" {
  description = "VPC ID for security group placement."
  type        = string
}

variable "subnet_ids" {
  description = "Private subnet IDs for ECS tasks."
  type        = list(string)
}

variable "container_image" {
  description = "Docker image URI (e.g., 123456789.dkr.ecr.us-east-1.amazonaws.com/app:latest)."
  type        = string
}

variable "container_port" {
  description = "Port the container listens on."
  type        = number
  default     = 8080
}

variable "cpu" {
  description = "CPU units for the task (256, 512, 1024, 2048, 4096)."
  type        = number
  default     = 256

  validation {
    condition     = contains([256, 512, 1024, 2048, 4096], var.cpu)
    error_message = "cpu must be a valid Fargate CPU value."
  }
}

variable "memory" {
  description = "Memory in MiB for the task."
  type        = number
  default     = 512
}

variable "desired_count" {
  description = "Initial number of running tasks."
  type        = number
  default     = 2
}

variable "min_count" {
  description = "Minimum number of tasks for autoscaling."
  type        = number
  default     = 2
}

variable "max_count" {
  description = "Maximum number of tasks for autoscaling."
  type        = number
  default     = 10
}

variable "health_check_path" {
  description = "Health check path for the ALB target group. Only used when enable_load_balancer is true."
  type        = string
  default     = "/health"
}

variable "enable_load_balancer" {
  description = "Whether to create ALB target group and listener rule."
  type        = bool
  default     = false
}

variable "listener_arn" {
  description = "ARN of the ALB listener. Required when enable_load_balancer is true."
  type        = string
  default     = null
}

# The ECS task security group ingress rule used to be `cidr_ipv4 = "0.0.0.0/0"`
# when a load balancer was attached. That is wrong shape: it bypasses the ALB
# as a chokepoint (any host that can reach the task IP:port on the VPC network
# — or the wider internet if the task ever runs with a public IP — reaches the
# app directly, past every WAF/listener-rule/TLS control the ALB is there to
# provide). Correct shape: ingress from the ALB's own security group only. The
# module now requires the caller to pass that SG id when enable_load_balancer
# is true, so the ingress rule can be a `referenced_security_group_id`.
variable "alb_security_group_id" {
  description = "Security group ID of the ALB that fronts the ECS tasks. REQUIRED when enable_load_balancer is true; the container-port ingress rule allows traffic only from this SG. Ignored when enable_load_balancer is false."
  type        = string
  default     = null
}

variable "listener_rule_priority" {
  description = "Priority for the ALB listener rule. Required when enable_load_balancer is true."
  type        = number
  default     = null
}

variable "path_patterns" {
  description = "URL path patterns for ALB routing (e.g., [\"/api/cards/*\"])."
  type        = list(string)
  default     = []
}

variable "host_headers" {
  description = "Host header values for ALB routing."
  type        = list(string)
  default     = []
}

variable "environment_variables" {
  description = "Environment variables injected into the container."
  type        = map(string)
  default     = {}
}

variable "secrets" {
  description = "Secrets injected into the container. Map of name to SSM/Secrets Manager ARN."
  type        = map(string)
  default     = {}
}

variable "additional_task_policy_statements" {
  description = "Additional IAM policy statements for the task role."
  type = list(object({
    effect    = string
    actions   = list(string)
    resources = list(string)
  }))
  default = []
}

variable "assign_public_ip" {
  description = "Whether to assign a public IP to tasks. Should be false for private subnets."
  type        = bool
  default     = false
}

variable "alarm_actions" {
  description = "List of ARNs to notify when alarms trigger (e.g., SNS topic ARNs)."
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
