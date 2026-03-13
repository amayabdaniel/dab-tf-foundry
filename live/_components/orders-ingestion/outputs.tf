output "function_name" {
  description = "Name of the orders-ingestion Lambda function."
  value       = module.processor.function_name
}

output "function_arn" {
  description = "ARN of the orders-ingestion Lambda function."
  value       = module.processor.function_arn
}

output "queue_url" {
  description = "URL of the order-events SQS queue."
  value       = module.order_queue.queue_url
}

output "queue_arn" {
  description = "ARN of the order-events SQS queue."
  value       = module.order_queue.queue_arn
}

output "dlq_url" {
  description = "URL of the order-events dead-letter queue."
  value       = module.order_queue.dlq_url
}

output "dashboard_name" {
  description = "Name of the CloudWatch dashboard."
  value       = module.observability.dashboard_name
}
