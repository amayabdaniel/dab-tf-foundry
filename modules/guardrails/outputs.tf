output "permissions_boundary_arn" {
  description = "ARN of the IAM permissions boundary policy."
  value       = aws_iam_policy.permissions_boundary.arn
}

output "budget_name" {
  description = "Name of the AWS budget."
  value       = aws_budgets_budget.environment.name
}

output "config_rule_arns" {
  description = "ARNs of the AWS Config rules."
  value = var.enable_config_rules ? {
    required_tags  = aws_config_config_rule.required_tags[0].arn
    rds_encryption = aws_config_config_rule.rds_encryption[0].arn
    rds_no_public  = aws_config_config_rule.rds_no_public[0].arn
    rds_backup     = aws_config_config_rule.rds_backup[0].arn
    ecs_awsvpc     = aws_config_config_rule.ecs_awsvpc[0].arn
    log_retention  = aws_config_config_rule.log_retention[0].arn
    sqs_encryption = aws_config_config_rule.sqs_encryption[0].arn
  } : {}
}
