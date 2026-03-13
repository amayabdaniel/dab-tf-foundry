output "service_arn" {
  description = "ARN of the ECS service."
  value       = aws_ecs_service.this.id
}

output "service_name" {
  description = "Name of the ECS service."
  value       = aws_ecs_service.this.name
}

output "task_definition_arn" {
  description = "ARN of the ECS task definition."
  value       = aws_ecs_task_definition.this.arn
}

output "task_role_arn" {
  description = "ARN of the ECS task IAM role."
  value       = aws_iam_role.task.arn
}

output "security_group_id" {
  description = "ID of the ECS task security group."
  value       = aws_security_group.this.id
}

output "target_group_arn" {
  description = "ARN of the ALB target group. Null if load balancer is not enabled."
  value       = var.enable_load_balancer ? aws_lb_target_group.this[0].arn : null
}

output "log_group_name" {
  description = "Name of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "alarm_arns" {
  description = "ARNs of all CloudWatch alarms created by this module."
  value = [
    aws_cloudwatch_metric_alarm.high_cpu.arn,
    aws_cloudwatch_metric_alarm.running_task_count.arn,
  ]
}
