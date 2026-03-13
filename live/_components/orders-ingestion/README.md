# orders-ingestion

Lambda-based microservice that ingests order events asynchronously from SQS.

## Architecture

- SQS queue receives order events from upstream producers
- Lambda processes messages in batches of 5
- Failed messages are retried up to 3 times, then routed to a DLQ
- Uses `ReportBatchItemFailures` so only failed messages are retried

## Modules Used

| Module | Purpose |
|--------|---------|
| `queue` | SQS queue + DLQ with encryption and alarms |
| `function` | Lambda with SQS trigger, IAM, alarms |

## Deploy

```bash
cd live/dev/orders-ingestion
terragrunt init
terragrunt plan
terragrunt apply
```
