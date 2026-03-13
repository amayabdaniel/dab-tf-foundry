output "function_name" {
  description = "Name of the Lambda function."
  value       = aws_lambda_function.this.function_name
}

output "function_arn" {
  description = "ARN of the Lambda function."
  value       = aws_lambda_function.this.arn
}

output "role_arn" {
  description = "ARN of the Lambda execution role."
  value       = aws_iam_role.this.arn
}

output "log_group_name" {
  description = "Name of the CloudWatch log group."
  value       = aws_cloudwatch_log_group.this.name
}

output "alarm_arns" {
  description = "ARNs of all CloudWatch alarms created by this module."
  value = [
    aws_cloudwatch_metric_alarm.errors.arn,
    aws_cloudwatch_metric_alarm.throttles.arn,
  ]
}
