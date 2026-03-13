# =============================================================================
# orders-ingestion
#
# Lambda-based microservice that ingests order events from SQS.
# Processes trading card orders asynchronously with DLQ for failures.
#
# In production, module sources would reference a git tag or private registry:
#   source = "git::https://github.com/fanatics/dab-tf-foundry.git//modules/function?ref=v1.0.0"
# =============================================================================

# -- Package the Lambda handler --
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/handler.zip"
}

# -- SQS queue for order events --
module "order_queue" {
  source = "../../../modules/queue"

  queue_name                 = "order-events"
  environment                = var.environment
  visibility_timeout_seconds = 90 # 3x Lambda timeout
  max_receive_count          = 3

  alarm_actions = [var.alarm_sns_topic_arn]
}

# -- Lambda function --
module "processor" {
  source = "../../../modules/function"

  function_name    = "orders-ingestion"
  environment      = var.environment
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"
  timeout          = 30
  memory_size      = 256

  sqs_event_source_arn = module.order_queue.queue_arn
  batch_size           = 5

  reserved_concurrent_executions = var.reserved_concurrent_executions

  environment_variables = {
    QUEUE_URL = module.order_queue.queue_url
    LOG_LEVEL = var.environment == "prod" ? "INFO" : "DEBUG"
  }

  alarm_actions = [var.alarm_sns_topic_arn]
}

# -- Observability --
module "observability" {
  source = "../../../modules/observability"

  service_name = "orders-ingestion"
  environment  = var.environment
  service_type = "function"

  log_group_name       = module.processor.log_group_name
  lambda_function_name = module.processor.function_name
  sqs_queue_name       = module.order_queue.queue_name
  dlq_queue_name       = module.order_queue.dlq_name
  alarm_arns           = concat(module.processor.alarm_arns, module.order_queue.alarm_arns)
  alarm_actions        = [var.alarm_sns_topic_arn]
}
