# manufacturing-orchestrator

Fargate worker that consumes manufacturing jobs from SQS. No public load balancer.

## Architecture

- SQS queue receives manufacturing job messages
- Fargate worker polls the queue and processes jobs
- Failed messages are retried up to 3 times, then routed to a DLQ
- CPU/memory autoscaling (queue-depth scaling is a future enhancement)

## Modules Used

| Module | Purpose |
|--------|---------|
| `queue` | SQS queue + DLQ with encryption and alarms |
| `container` | Fargate worker (no ALB), autoscaling, alarms |

## Deploy

```bash
cd live/dev/manufacturing-orchestrator
terragrunt init
terragrunt plan
terragrunt apply
```
