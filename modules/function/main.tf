locals {
  name_prefix = "${var.function_name}-${var.environment}"

  standard_tags = {
    Service     = var.function_name
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "function"
  }

  all_tags = merge(local.standard_tags, var.tags)

  has_vpc = length(var.subnet_ids) > 0
}

# -----------------------------------------------------------------------------
# CloudWatch Log Group
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_log_group" "this" {
  name              = "/aws/lambda/${local.name_prefix}"
  retention_in_days = var.log_retention_days
  tags              = local.all_tags
}

# -----------------------------------------------------------------------------
# IAM Role
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "this" {
  name               = "${local.name_prefix}-lambda"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
  tags               = local.all_tags
}

# Basic execution: CloudWatch Logs
resource "aws_iam_role_policy_attachment" "basic_execution" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# VPC access (conditional)
resource "aws_iam_role_policy_attachment" "vpc_access" {
  count      = local.has_vpc ? 1 : 0
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# SQS poller permissions (conditional)
data "aws_iam_policy_document" "sqs_access" {
  count = var.sqs_event_source_arn != null ? 1 : 0

  statement {
    effect = "Allow"
    actions = [
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
    ]
    resources = [var.sqs_event_source_arn]
  }
}

resource "aws_iam_role_policy" "sqs_access" {
  count  = var.sqs_event_source_arn != null ? 1 : 0
  name   = "sqs-event-source"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.sqs_access[0].json
}

# Additional policies
data "aws_iam_policy_document" "additional" {
  count = length(var.additional_policy_statements) > 0 ? 1 : 0

  dynamic "statement" {
    for_each = var.additional_policy_statements
    content {
      effect    = statement.value.effect
      actions   = statement.value.actions
      resources = statement.value.resources
    }
  }
}

resource "aws_iam_role_policy" "additional" {
  count  = length(var.additional_policy_statements) > 0 ? 1 : 0
  name   = "additional"
  role   = aws_iam_role.this.id
  policy = data.aws_iam_policy_document.additional[0].json
}

# -----------------------------------------------------------------------------
# Lambda Function
# -----------------------------------------------------------------------------
resource "aws_lambda_function" "this" {
  function_name    = local.name_prefix
  filename         = var.filename
  source_code_hash = var.source_code_hash
  handler          = var.handler
  runtime          = var.runtime
  timeout          = var.timeout
  memory_size      = var.memory_size
  role             = aws_iam_role.this.arn
  tags             = local.all_tags

  reserved_concurrent_executions = var.reserved_concurrent_executions

  environment {
    variables = merge(
      {
        ENVIRONMENT  = var.environment
        SERVICE_NAME = var.function_name
      },
      var.environment_variables,
    )
  }

  dynamic "vpc_config" {
    for_each = local.has_vpc ? [1] : []
    content {
      subnet_ids         = var.subnet_ids
      security_group_ids = var.security_group_ids
    }
  }

  depends_on = [aws_cloudwatch_log_group.this]
}

# -----------------------------------------------------------------------------
# SQS Event Source Mapping (conditional)
# -----------------------------------------------------------------------------
resource "aws_lambda_event_source_mapping" "sqs" {
  count = var.sqs_event_source_arn != null ? 1 : 0

  event_source_arn = var.sqs_event_source_arn
  function_name    = aws_lambda_function.this.arn
  batch_size       = var.batch_size
  enabled          = true

  function_response_types = ["ReportBatchItemFailures"]
}

# -----------------------------------------------------------------------------
# CloudWatch Alarms
# -----------------------------------------------------------------------------
resource "aws_cloudwatch_metric_alarm" "errors" {
  alarm_name          = "${local.name_prefix}-errors"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Errors"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda errors detected for ${local.name_prefix}"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = local.all_tags

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}

resource "aws_cloudwatch_metric_alarm" "throttles" {
  alarm_name          = "${local.name_prefix}-throttles"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "Throttles"
  namespace           = "AWS/Lambda"
  period              = 60
  statistic           = "Sum"
  threshold           = 0
  alarm_description   = "Lambda throttles detected for ${local.name_prefix}"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.alarm_actions
  tags                = local.all_tags

  dimensions = {
    FunctionName = aws_lambda_function.this.function_name
  }
}
