output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.service.dashboard_name
}

output "dashboard_arn" {
  description = "ARN of the CloudWatch dashboard."
  value       = aws_cloudwatch_dashboard.service.dashboard_arn
}

output "composite_alarm_arn" {
  description = "ARN of the composite alarm. Null if no alarm_arns provided."
  value       = length(var.alarm_arns) > 0 ? aws_cloudwatch_composite_alarm.service[0].arn : null
}

output "log_error_alarm_arn" {
  description = "ARN of the application log error alarm."
  value       = aws_cloudwatch_metric_alarm.log_errors.arn
}

output "log_error_metric_filter_name" {
  description = "Name of the log error metric filter."
  value       = aws_cloudwatch_log_metric_filter.errors.name
}
