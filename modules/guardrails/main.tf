locals {
  name_prefix = "foundry-guardrails-${var.environment}"

  standard_tags = {
    Environment = var.environment
    ManagedBy   = "terraform"
    Module      = "guardrails"
  }

  all_tags = merge(local.standard_tags, var.tags)
}

# -----------------------------------------------------------------------------
# AWS Config Rules — detect drift from platform standards
# Requires AWS Config recorder to be enabled (managed by platform team)
# -----------------------------------------------------------------------------

# Ensure all resources have required tags
resource "aws_config_config_rule" "required_tags" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${local.name_prefix}-required-tags"
  description = "Ensures resources have required tags: ${join(", ", var.required_tag_keys)}"
  tags        = local.all_tags

  source {
    owner             = "AWS"
    source_identifier = "REQUIRED_TAGS"
  }

  input_parameters = jsonencode({
    for i, key in var.required_tag_keys :
    "tag${i + 1}Key" => key
  })
}

# Ensure RDS instances are encrypted
resource "aws_config_config_rule" "rds_encryption" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${local.name_prefix}-rds-encrypted"
  description = "Ensures all RDS instances have storage encryption enabled"
  tags        = local.all_tags

  source {
    owner             = "AWS"
    source_identifier = "RDS_STORAGE_ENCRYPTED"
  }
}

# Ensure RDS instances are not publicly accessible
resource "aws_config_config_rule" "rds_no_public" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${local.name_prefix}-rds-no-public"
  description = "Ensures RDS instances are not publicly accessible"
  tags        = local.all_tags

  source {
    owner             = "AWS"
    source_identifier = "RDS_INSTANCE_PUBLIC_ACCESS_CHECK"
  }
}

# Ensure RDS instances have backups enabled
resource "aws_config_config_rule" "rds_backup" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${local.name_prefix}-rds-backup"
  description = "Ensures RDS instances have automated backups enabled"
  tags        = local.all_tags

  source {
    owner             = "AWS"
    source_identifier = "DB_INSTANCE_BACKUP_ENABLED"
  }
}

# Ensure ECS tasks use awsvpc networking
resource "aws_config_config_rule" "ecs_awsvpc" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${local.name_prefix}-ecs-awsvpc"
  description = "Ensures ECS task definitions use awsvpc network mode"
  tags        = local.all_tags

  source {
    owner             = "AWS"
    source_identifier = "ECS_TASK_DEFINITION_NETWORK_MODE_CHECK"
  }
}

# Ensure CloudWatch log groups have retention set
resource "aws_config_config_rule" "log_retention" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${local.name_prefix}-log-retention"
  description = "Ensures CloudWatch log groups have retention ≤ ${var.max_log_retention_days} days"
  tags        = local.all_tags

  source {
    owner             = "AWS"
    source_identifier = "CW_LOGGROUP_RETENTION_PERIOD_CHECK"
  }

  input_parameters = jsonencode({
    MaxRetentionPeriodInDays = var.max_log_retention_days
  })
}

# Ensure SQS queues have encryption enabled
resource "aws_config_config_rule" "sqs_encryption" {
  count = var.enable_config_rules ? 1 : 0

  name        = "${local.name_prefix}-sqs-encrypted"
  description = "Ensures SQS queues have server-side encryption enabled"
  tags        = local.all_tags

  source {
    owner             = "AWS"
    source_identifier = "SQS_QUEUE_ENCRYPTED"
  }
}

# -----------------------------------------------------------------------------
# IAM — Permissions boundary for service roles
# Prevents services from escalating beyond platform-approved actions
# -----------------------------------------------------------------------------
data "aws_iam_policy_document" "permissions_boundary" {
  # Allow standard compute and observability actions
  statement {
    sid    = "AllowComputeAndObservability"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "sqs:SendMessage",
      "sqs:ReceiveMessage",
      "sqs:DeleteMessage",
      "sqs:GetQueueAttributes",
      "sqs:ChangeMessageVisibility",
      "secretsmanager:GetSecretValue",
      "ssm:GetParameters",
      "ssmmessages:*",
      "xray:PutTraceSegments",
      "xray:PutTelemetryRecords",
    ]
    resources = ["*"]
  }

  # Deny IAM privilege escalation
  statement {
    sid    = "DenyIAMEscalation"
    effect = "Deny"
    actions = [
      "iam:CreateUser",
      "iam:CreateRole",
      "iam:AttachRolePolicy",
      "iam:PutRolePolicy",
      "iam:CreatePolicy",
      "iam:DeleteRole",
      "iam:DeletePolicy",
      "iam:UpdateAssumeRolePolicy",
    ]
    resources = ["*"]
  }

  # Deny destructive account-level actions
  statement {
    sid    = "DenyDestructiveActions"
    effect = "Deny"
    actions = [
      "organizations:*",
      "account:*",
      "ec2:DeleteVpc",
      "ec2:DeleteSubnet",
      "rds:DeleteDBInstance",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "permissions_boundary" {
  name        = "${local.name_prefix}-boundary"
  description = "Permissions boundary for ${var.environment} service roles"
  policy      = data.aws_iam_policy_document.permissions_boundary.json
  tags        = local.all_tags
}

# -----------------------------------------------------------------------------
# Budget Alert — cost guardrail per environment
# -----------------------------------------------------------------------------
resource "aws_budgets_budget" "environment" {
  name         = "${local.name_prefix}-monthly"
  budget_type  = "COST"
  time_unit    = "MONTHLY"
  limit_amount = var.environment == "prod" ? "5000" : "1000"
  limit_unit   = "USD"

  cost_filter {
    name   = "TagKeyValue"
    values = ["user:Environment$${var.environment}"]
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 80
    threshold_type            = "PERCENTAGE"
    notification_type         = "FORECASTED"
    subscriber_sns_topic_arns = var.alarm_actions
  }

  notification {
    comparison_operator       = "GREATER_THAN"
    threshold                 = 100
    threshold_type            = "PERCENTAGE"
    notification_type         = "ACTUAL"
    subscriber_sns_topic_arns = var.alarm_actions
  }
}
