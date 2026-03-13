# queue

Deploys an SQS queue with a dead-letter queue and secure defaults.

## Features

- Main queue with configurable visibility timeout and retention
- Dead-letter queue with redrive policy
- Server-side encryption (SQS-managed by default, KMS optional)
- DLQ alarm for message visibility
- Optional queue policy
- Standardized tagging

## Usage

```hcl
module "order_queue" {
  source = "../../../modules/queue"

  queue_name                 = "order-events"
  environment                = "prod"
  visibility_timeout_seconds = 60
  max_receive_count          = 3

  alarm_actions = [var.alarm_sns_topic_arn]
}
```
