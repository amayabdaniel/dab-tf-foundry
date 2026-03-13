locals {
  name_prefix = "${var.queue_name}-${var.environment}"

  standard_tags = {
    Service     = var.queue_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "queue"
  }

  all_tags = merge(local.standard_tags, var.tags)
}

# -----------------------------------------------------------------------------
# Dead-Letter Queue
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "dlq" {
  name                      = "${local.name_prefix}-dlq"
  message_retention_seconds = var.dlq_message_retention_seconds
  sqs_managed_sse_enabled   = var.kms_master_key_id == "alias/aws/sqs" ? true : null
  kms_master_key_id         = var.kms_master_key_id != "alias/aws/sqs" ? var.kms_master_key_id : null
  tags                      = local.all_tags
}

# -----------------------------------------------------------------------------
# Main Queue
# -----------------------------------------------------------------------------
resource "aws_sqs_queue" "this" {
  name                       = local.name_prefix
  visibility_timeout_seconds = var.visibility_timeout_seconds
  message_retention_seconds  = var.message_retention_seconds
  sqs_managed_sse_enabled    = var.kms_master_key_id == "alias/aws/sqs" ? true : null
  kms_master_key_id          = var.kms_master_key_id != "alias/aws/sqs" ? var.kms_master_key_id : null
  tags                       = local.all_tags

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.dlq.arn
    maxReceiveCount     = var.max_receive_count
  })
}

# -----------------------------------------------------------------------------
# Queue Policy (optional)
# -----------------------------------------------------------------------------
resource "aws_sqs_queue_policy" "this" {
  count     = var.queue_policy != null ? 1 : 0
  queue_url = aws_sqs_queue.this.id
  policy    = var.queue_policy
}

# -----------------------------------------------------------------------------
# DLQ Alarm — alerts when messages land in the dead-letter queue
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "dlq_messages" {
  alarm_name          = "${local.name_prefix}-dlq-visible"
  comparison_operator = "GreaterThanOrEqualToThreshold"
  evaluation_periods  = 1
  metric_name         = "ApproximateNumberOfMessagesVisible"
  namespace           = "AWS/SQS"
  period              = 60
  statistic           = "Sum"
  threshold           = var.dlq_alarm_threshold
  alarm_description   = "Messages visible in DLQ for ${local.name_prefix}"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = local.all_tags

  dimensions = {
    QueueName = aws_sqs_queue.dlq.name
  }
}
