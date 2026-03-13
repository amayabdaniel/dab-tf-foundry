output "db_instance_arn" {
  description = "ARN of the RDS instance."
  value       = aws_db_instance.this.arn
}

output "address" {
  description = "Hostname of the RDS instance."
  value       = aws_db_instance.this.address
}

output "port" {
  description = "Port of the RDS instance."
  value       = aws_db_instance.this.port
}

output "secret_arn" {
  description = "ARN of the Secrets Manager secret for the master password."
  value       = aws_db_instance.this.master_user_secret[0].secret_arn
}

output "security_group_id" {
  description = "ID of the RDS security group."
  value       = aws_security_group.this.id
}

output "db_name" {
  description = "Name of the default database."
  value       = aws_db_instance.this.db_name
}

output "identifier" {
  description = "Identifier of the RDS instance."
  value       = aws_db_instance.this.identifier
}

output "alarm_arns" {
  description = "ARNs of all CloudWatch alarms created by this module."
  value = [
    aws_cloudwatch_metric_alarm.high_cpu.arn,
    aws_cloudwatch_metric_alarm.low_storage.arn,
    aws_cloudwatch_metric_alarm.high_connections.arn,
  ]
}
