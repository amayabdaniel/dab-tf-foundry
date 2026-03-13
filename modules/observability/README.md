# observability

Centralized observability module that provisions a CloudWatch dashboard, log-based metric filters, and a composite alarm for any catalog service.

## Features

- **CloudWatch dashboard** — auto-generated per service type (container, function, worker) with widgets for compute, queue, database, and application logs
- **Log metric filter** — extracts error counts from application logs into a custom metric namespace
- **Log error alarm** — fires when application log errors exceed a threshold
- **Composite alarm** — aggregates all child alarms into a single pager (fires if ANY child alarm is in ALARM state)
- **Pluggable** — works with any combination of compute + queue + database

## Supported Service Types

| Type | Dashboard Widgets |
|------|-------------------|
| `container` | CPU, memory, running task count + optional queue + optional DB |
| `worker` | Same as container (no ALB metrics) |
| `function` | Invocations, duration (p50/p99), errors & throttles + optional queue |

## Usage

```hcl
module "observability" {
  source = "../../../modules/observability"

  service_name = "card-catalog-api"
  environment  = "prod"
  service_type = "container"

  log_group_name   = module.api.log_group_name
  ecs_cluster_name = "shared-prod"
  ecs_service_name = module.api.service_name

  db_instance_identifier = "card-catalog-prod"

  alarm_arns = [
    module.api.high_cpu_alarm_arn,
    module.database.high_cpu_alarm_arn,
  ]

  alarm_actions = [var.alarm_sns_topic_arn]
}
```
