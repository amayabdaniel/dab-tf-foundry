# function

Deploys a Lambda function with opinionated defaults for event-driven microservices.

## Features

- ZIP-based deployment (caller owns packaging)
- Optional SQS event source mapping with `ReportBatchItemFailures`
- Optional VPC attachment
- Reserved concurrency support
- CloudWatch log group with configurable retention
- Error and throttle alarms
- Least-privilege IAM with extensible policy statements
- Standardized tagging

## Usage

```hcl
data "archive_file" "lambda" {
  type        = "zip"
  source_dir  = "${path.module}/src"
  output_path = "${path.module}/build/handler.zip"
}

module "my_lambda" {
  source = "../../../modules/function"

  function_name    = "my-processor"
  environment      = "prod"
  filename         = data.archive_file.lambda.output_path
  source_code_hash = data.archive_file.lambda.output_base64sha256
  handler          = "handler.lambda_handler"
  runtime          = "python3.12"

  sqs_event_source_arn = module.my_queue.queue_arn
  batch_size           = 5

  environment_variables = {
    QUEUE_URL = module.my_queue.queue_url
  }

  alarm_actions = [var.alarm_sns_topic_arn]
}
```
