# guardrails

Baseline guardrail module that enforces platform standards via AWS Config rules, IAM permissions boundaries, and budget alerts.

## Features

- **AWS Config rules** — Detect non-compliant resources:
  - Required tags on all resources
  - RDS encryption, no public access, backups enabled
  - ECS awsvpc network mode
  - CloudWatch log retention limits
  - SQS encryption
- **IAM permissions boundary** — Prevents service roles from escalating privileges or performing destructive account-level actions
- **Budget alert** — Monthly cost guardrail per environment with forecasted (80%) and actual (100%) notifications

## Prerequisites

- AWS Config recorder must be enabled in the account (typically managed by platform team)

## Usage

```hcl
module "guardrails" {
  source = "../../../modules/guardrails"

  environment        = "prod"
  required_tag_keys  = ["Service", "Environment", "ManagedBy"]
  enable_config_rules = true

  alarm_actions = [var.alarm_sns_topic_arn]
}
```

The `permissions_boundary_arn` output can be attached to service roles to enforce guardrails at the IAM level:

```hcl
resource "aws_iam_role" "service" {
  name                 = "my-service"
  permissions_boundary = module.guardrails.permissions_boundary_arn
  # ...
}
```
