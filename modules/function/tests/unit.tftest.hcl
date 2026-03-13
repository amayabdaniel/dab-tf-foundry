# ------------------------------------------------------------------------------
# Unit tests for function module — variable validation & plan assertions
# ------------------------------------------------------------------------------

mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.lambda_assume
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"lambda.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}" }
  }
  override_data {
    target = data.aws_iam_policy_document.sqs_access
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  override_data {
    target = data.aws_iam_policy_document.additional
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  function_name    = "test-func"
  environment      = "dev"
  filename         = "lambda.zip"
  source_code_hash = "dGVzdGhhc2g="
}

run "reject_uppercase_function_name" {
  command = plan

  variables {
    function_name = "InvalidName"
  }

  expect_failures = [var.function_name]
}

run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "reject_timeout_over_900" {
  command = plan

  variables {
    timeout = 1000
  }

  expect_failures = [var.timeout]
}

run "reject_memory_below_128" {
  command = plan

  variables {
    memory_size = 64
  }

  expect_failures = [var.memory_size]
}

run "valid_configuration_creates_lambda" {
  command = plan

  assert {
    condition     = aws_lambda_function.this.function_name == "test-func-dev"
    error_message = "Lambda function name must follow {name}-{env} pattern."
  }

  assert {
    condition     = aws_lambda_function.this.runtime == "python3.12"
    error_message = "Default runtime must be python3.12."
  }

  assert {
    condition     = aws_lambda_function.this.timeout == 30
    error_message = "Default timeout must be 30."
  }
}
