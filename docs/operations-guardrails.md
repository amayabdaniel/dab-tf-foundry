# Operations & Guardrails

## Resilience and Scaling

### ECS Services
- **Deployment circuit breaker** is enabled with automatic rollback. If new tasks fail health checks, ECS rolls back to the previous task definition automatically.
- **Autoscaling** uses target-tracking policies for CPU (70% target) and memory (80% target). Scale-out cooldown is 60 seconds; scale-in cooldown is 300 seconds to prevent flapping.
- **Multi-AZ**: Tasks are distributed across subnets in multiple availability zones. The `min_count` default of 2 ensures at least one task survives an AZ failure.
- **Health checks**: ALB-backed services use HTTP health checks. Unhealthy tasks are deregistered and replaced.
- **Deregistration delay**: Set to 30 seconds to allow in-flight requests to drain before task removal.

### Lambda
- **Reserved concurrency** prevents a single function from consuming all account-level concurrency. Default is uncapped; production services should set an explicit limit.
- **SQS retry behavior**: Messages are retried up to `max_receive_count` times (default 3). Failed messages are routed to a DLQ.
- **ReportBatchItemFailures**: The Lambda event source mapping is configured to support partial batch failures, so only failed messages are retried — not the entire batch.
- **Timeout alignment**: SQS visibility timeout should be ≥ 6x the Lambda timeout to prevent duplicate processing during retries.

### SQS
- **Dead-letter queues**: Every queue gets a DLQ with a 14-day retention period. DLQ alarms fire when messages become visible.
- **Redrive policy**: Configurable `max_receive_count` controls how many times a message is retried before DLQ routing.
- **Visibility timeout**: Set per-service based on expected processing time.

### RDS PostgreSQL
- **Multi-AZ**: Disabled by default for dev; should be enabled for production workloads.
- **Automated backups**: 7-day retention by default, with a defined backup window.
- **Storage autoscaling**: Enabled by default up to `max_allocated_storage` to handle growth without manual intervention.
- **Deletion protection**: Enabled by default. Must be explicitly disabled for teardown.
- **Final snapshot**: Required in prod, skipped in dev.

## Security and IAM Model

### Principle of Least Privilege
- **ECS execution role**: Only has permissions to pull ECR images, write CloudWatch Logs, and read specific secrets.
- **ECS task role**: Starts with ECS Exec permissions only. Application-specific permissions are added via `additional_task_policy_statements`.
- **Lambda role**: Basic execution (CloudWatch Logs) + VPC access (if configured) + SQS access (if configured). Extended via `additional_policy_statements`.
- **No wildcard resource ARNs** except where required by AWS (SSM messages for ECS Exec).

### Network Security
- All compute in private subnets — no public IPs assigned.
- RDS in dedicated data subnets — not publicly accessible.
- Security groups use specific port/protocol rules:
  - ECS API services: ingress on container port only.
  - ECS workers: no ingress rules.
  - RDS: ingress on port 5432, source-scoped to specific application security groups.

### Secrets
- RDS master passwords managed by Secrets Manager (`manage_master_user_password = true`).
- ECS containers receive secrets via `valueFrom` references — secrets are never in environment variables or Terraform state.

### Encryption
- RDS: storage encryption enabled.
- SQS: SQS-managed SSE by default.
- CloudWatch Logs: encrypted by AWS.
- All data in transit uses TLS (ALB HTTPS, RDS SSL).

## Observability Standards

### Logging
- Every service gets a dedicated CloudWatch log group.
- ECS: `/ecs/{service}-{env}` with `awslogs` driver.
- Lambda: `/aws/lambda/{function}-{env}`.
- Default retention: 30 days. Adjust via `log_retention_days`.
- Structured JSON logging is recommended at the application level.

### Alarms (built into modules)

| Module | Alarm | Threshold |
|--------|-------|-----------|
| `container` | High CPU | > 85% avg for 3 minutes |
| `container` | Low task count | < min_count for 2 minutes |
| `function` | Errors | > 0 for 2 minutes |
| `function` | Throttles | > 0 for 2 minutes |
| `queue` | DLQ visible messages | ≥ 1 |
| `database` | High CPU | > 80% avg for 15 minutes |
| `database` | Low storage | < 5 GB |
| `database` | High connections | > 50 |

All alarms route to the shared SNS topic via `alarm_actions`.

### Recommended Additions (application-level)
- Application-level latency and error rate dashboards.
- X-Ray tracing for ECS and Lambda.
- RDS Performance Insights for query analysis.
- SQS queue depth dashboards.

## Cost Governance

### Tagging for Cost Allocation
All modules apply `Service`, `Environment`, `ManagedBy`, and `Module` tags. These enable:
- Cost allocation by service and environment.
- AWS Cost Explorer filtering.
- Budget alerts per team/service.

### Right-Sizing Guidance

| Resource | Dev | Prod |
|----------|-----|------|
| ECS CPU/Memory | 256/512 | 512/1024+ based on load testing |
| ECS min_count | 1 | 2+ |
| RDS instance class | db.t4g.micro | db.t4g.small+ |
| RDS Multi-AZ | false | true |
| Lambda memory | 128 MB | Based on profiling |
| Lambda reserved concurrency | Unreserved | Set explicit limit |
| Log retention | 7 days | 30-90 days |

### Cost Control Mechanisms
- **ECS autoscaling** with scale-in cooldowns prevents over-provisioning.
- **RDS storage autoscaling** avoids pre-allocating excessive storage.
- **Lambda reserved concurrency** caps spend on event-driven workloads.
- **SQS** has no per-queue cost — cost is driven by message volume.
- **CloudWatch log retention** should be reduced for dev environments.

### Dev vs Prod Differences

| Setting | Dev | Prod |
|---------|-----|------|
| ECS desired_count | 1 | 2+ |
| RDS multi_az | false | true |
| RDS deletion_protection | false (opt) | true |
| RDS final_snapshot | skipped | required |
| Lambda reserved_concurrency | -1 | explicit |
| Log retention | 7 days | 30 days |
| Alarm actions | optional | required |
