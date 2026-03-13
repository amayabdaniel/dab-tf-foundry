# ------------------------------------------------------------------------------
# Unit tests for observability module — variable validation
# ------------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  service_name   = "test-svc"
  environment    = "dev"
  service_type   = "container"
  log_group_name = "/ecs/test-svc-dev"
}

run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "reject_invalid_service_type" {
  command = plan

  variables {
    service_type = "server"
  }

  expect_failures = [var.service_type]
}

run "valid_configuration_creates_dashboard" {
  command = plan

  assert {
    condition     = aws_cloudwatch_dashboard.service.dashboard_name == "test-svc-dev"
    error_message = "Dashboard name must follow {service}-{env} pattern."
  }

  assert {
    condition     = aws_cloudwatch_log_metric_filter.errors.name == "test-svc-dev-log-errors"
    error_message = "Metric filter name must follow naming convention."
  }
}
