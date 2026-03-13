# ------------------------------------------------------------------------------
# Unit tests for queue module — variable validation & plan assertions
# ------------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  queue_name  = "test-queue"
  environment = "dev"
}

run "reject_uppercase_queue_name" {
  command = plan

  variables {
    queue_name = "InvalidUpper"
  }

  expect_failures = [var.queue_name]
}

run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "valid_configuration_creates_queue_and_dlq" {
  command = plan

  assert {
    condition     = aws_sqs_queue.this.name == "test-queue-dev"
    error_message = "Queue name must follow {name}-{env} pattern."
  }

  assert {
    condition     = aws_sqs_queue.dlq.name == "test-queue-dev-dlq"
    error_message = "DLQ name must follow {name}-{env}-dlq pattern."
  }
}
