# ------------------------------------------------------------------------------
# Unit tests for container module — variable validation & plan assertions
# ------------------------------------------------------------------------------

mock_provider "aws" {
  override_data {
    target = data.aws_iam_policy_document.ecs_assume
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[{\"Effect\":\"Allow\",\"Principal\":{\"Service\":\"ecs-tasks.amazonaws.com\"},\"Action\":\"sts:AssumeRole\"}]}" }
  }
  override_data {
    target = data.aws_iam_policy_document.execution_secrets
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  override_data {
    target = data.aws_iam_policy_document.ecs_exec
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  override_data {
    target = data.aws_iam_policy_document.additional
    values = { json = "{\"Version\":\"2012-10-17\",\"Statement\":[]}" }
  }
  override_data {
    target = data.aws_region.current
    values = { id = "us-east-1" }
  }
}

# Shared valid defaults for all required variables
variables {
  service_name    = "test-svc"
  environment     = "dev"
  cluster_arn     = "arn:aws:ecs:us-east-1:123456789012:cluster/main"
  vpc_id          = "vpc-0123456789abcdef0"
  subnet_ids      = ["subnet-0123456789abcdef0"]
  container_image = "123456789012.dkr.ecr.us-east-1.amazonaws.com/app:latest"
}

run "reject_uppercase_service_name" {
  command = plan

  variables {
    service_name = "MyService"
  }

  expect_failures = [var.service_name]
}

run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "reject_invalid_cpu" {
  command = plan

  variables {
    cpu = 999
  }

  expect_failures = [var.cpu]
}

run "valid_worker_creates_ecs_service" {
  command = plan

  assert {
    condition     = aws_ecs_service.this.name == "test-svc-dev"
    error_message = "ECS service name must follow {service}-{env} pattern."
  }

  assert {
    condition     = aws_cloudwatch_log_group.this.name == "/ecs/test-svc-dev"
    error_message = "Log group must follow /ecs/{service}-{env} pattern."
  }

  assert {
    condition     = aws_ecs_task_definition.this.cpu == "256"
    error_message = "Default CPU must be 256."
  }
}

run "valid_api_with_load_balancer" {
  command = plan

  variables {
    enable_load_balancer   = true
    listener_arn           = "arn:aws:elasticloadbalancing:us-east-1:123456789012:listener/app/main/1234567890123456/1234567890123456"
    listener_rule_priority = 100
    path_patterns          = ["/api/v1/*"]
  }

  assert {
    condition     = aws_lb_target_group.this[0].port == 8080
    error_message = "Target group port must match default container_port."
  }
}
