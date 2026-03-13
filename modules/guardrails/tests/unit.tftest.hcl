# ------------------------------------------------------------------------------
# Unit tests for guardrails module — variable validation & plan assertions
# ------------------------------------------------------------------------------

mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.permissions_boundary
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
}

variables {
  environment   = "dev"
  alarm_actions = []
}

run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "valid_configuration_creates_boundary" {
  command = plan

  assert {
    condition     = aws_iam_policy.permissions_boundary.name == "foundry-guardrails-dev-boundary"
    error_message = "Permissions boundary must follow foundry-guardrails-{env}-boundary pattern."
  }
}

run "valid_configuration_creates_budget" {
  command = plan

  assert {
    condition     = aws_budgets_budget.environment.name == "foundry-guardrails-dev-monthly"
    error_message = "Budget must follow foundry-guardrails-{env}-monthly pattern."
  }
}
