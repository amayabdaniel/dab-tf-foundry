# container

Deploys a Fargate service with opinionated defaults for security, observability, and autoscaling.

## Supported Patterns

- **API service**: Set `enable_load_balancer = true` to create an ALB target group and listener rule.
- **Worker service**: Set `enable_load_balancer = false` (default) for background processing with no inbound traffic.

## Features

- Fargate launch type with `awsvpc` networking
- Deployment circuit breaker with automatic rollback
- ECS Exec enabled for debugging
- CPU and memory target-tracking autoscaling
- CloudWatch log group with configurable retention
- Secrets injection via Secrets Manager / SSM
- Standardized tagging
- High-CPU and low-task-count alarms

## Usage

```hcl
module "my_api" {
  source = "../../../modules/container"

  service_name    = "my-api"
  environment     = "prod"
  cluster_arn     = var.ecs_cluster_arn
  vpc_id          = var.vpc_id
  subnet_ids      = var.private_subnet_ids
  container_image = "123456789.dkr.ecr.us-east-1.amazonaws.com/my-api:v1.2.0"
  container_port  = 8080

  enable_load_balancer   = true
  listener_arn           = var.alb_listener_arn
  listener_rule_priority = 100
  path_patterns          = ["/api/v1/*"]

  environment_variables = {
    SERVICE_NAME = "my-api"
  }

  secrets = {
    DB_PASSWORD = "arn:aws:secretsmanager:us-east-1:123456789:secret:my-api/db"
  }

  alarm_actions = [var.alarm_sns_topic_arn]
}
```
