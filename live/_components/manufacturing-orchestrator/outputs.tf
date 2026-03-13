output "service_arn" {
  description = "ARN of the manufacturing-orchestrator ECS service."
  value       = module.worker.service_arn
}

output "service_name" {
  description = "Name of the manufacturing-orchestrator ECS service."
  value       = module.worker.service_name
}

output "queue_url" {
  description = "URL of the manufacturing-jobs SQS queue."
  value       = module.job_queue.queue_url
}

output "queue_arn" {
  description = "ARN of the manufacturing-jobs SQS queue."
  value       = module.job_queue.queue_arn
}

output "dlq_url" {
  description = "URL of the manufacturing-jobs dead-letter queue."
  value       = module.job_queue.dlq_url
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = module.observability.dashboard_name
}
