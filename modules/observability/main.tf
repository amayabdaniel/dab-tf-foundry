locals {
  name_prefix = "${var.service_name}-${var.environment}"

  standard_tags = {
    Service     = var.service_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "observability"
  }

  all_tags = merge(local.standard_tags, var.tags)

  is_container = var.service_type == "container" || var.service_type == "worker"
  is_function  = var.service_type == "function"
  has_queue    = var.sqs_queue_name != null
  has_dlq      = var.dlq_queue_name != null
  has_db       = var.db_instance_identifier != null

  region = data.aws_region.current.id
}

data "aws_region" "current" {}

# -----------------------------------------------------------------------------
# Metric Filters — extract structured error counts from application logs
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_metric_filter" "errors" {
  name           = "${local.name_prefix}-log-errors"
  log_group_name = var.log_group_name
  pattern        = var.error_log_pattern

  metric_transformation {
    name          = "LogErrors"
    namespace     = "Foundry/${var.service_name}"
    value         = "1"
    default_value = "0"
  }
}

resource "aws_cloudwatch_metric_alarm" "log_errors" {
  alarm_name          = "${local.name_prefix}-log-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "LogErrors"
  namespace           = "Foundry/${var.service_name}"
  period              = 60
  statistic           = "Sum"
  threshold           = var.error_threshold
  alarm_description   = "Application log errors above ${var.error_threshold}/min for ${local.name_prefix}"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  treat_missing_data  = "notBreaching"
  tags                = local.all_tags
}

# -----------------------------------------------------------------------------
# Composite Alarm — single pager that fires if ANY child alarm fires
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_composite_alarm" "service" {
  count = length(var.alarm_arns) > 0 ? 1 : 0

  alarm_name        = "${local.name_prefix}-composite"
  alarm_description = "Composite alarm for ${local.name_prefix} — fires if any child alarm is in ALARM state"

  alarm_rule = join(" OR ", [
    for arn in var.alarm_arns : "ALARM(\"${arn}\")"
  ])

  actions_enabled = true
  alarm_actions   = var.alarm_actions
  ok_actions      = var.alarm_actions
  tags            = local.all_tags
}

# -----------------------------------------------------------------------------
# CloudWatch Dashboard — built via templatefile to avoid tuple type issues
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_dashboard" "service" {
  dashboard_name = local.name_prefix
  dashboard_body = templatefile("${path.module}/dashboard.json.tftpl", {
    service_name           = var.service_name
    environment            = var.environment
    service_type           = var.service_type
    region                 = local.region
    is_container           = local.is_container
    is_function            = local.is_function
    has_queue              = local.has_queue
    has_dlq                = local.has_dlq
    has_db                 = local.has_db
    ecs_cluster_name       = coalesce(var.ecs_cluster_name, "none")
    ecs_service_name       = coalesce(var.ecs_service_name, "none")
    lambda_function_name   = coalesce(var.lambda_function_name, "none")
    sqs_queue_name         = coalesce(var.sqs_queue_name, "none")
    dlq_queue_name         = coalesce(var.dlq_queue_name, "none")
    db_instance_identifier = coalesce(var.db_instance_identifier, "none")
    log_group_name         = var.log_group_name
  })
}
