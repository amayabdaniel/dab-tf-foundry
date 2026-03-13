output "service_arn" {
  description = "ARN of the card-catalog-api ECS service."
  value       = module.api.service_arn
}

output "service_name" {
  description = "Name of the card-catalog-api ECS service."
  value       = module.api.service_name
}

output "target_group_arn" {
  description = "ARN of the ALB target group."
  value       = module.api.target_group_arn
}

output "db_address" {
  description = "Hostname of the RDS instance."
  value       = module.database.address
}

output "db_secret_arn" {
  description = "ARN of the Secrets Manager secret for the DB master password."
  value       = module.database.secret_arn
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = module.observability.dashboard_name
}
