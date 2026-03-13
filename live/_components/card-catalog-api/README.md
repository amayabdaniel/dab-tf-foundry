# card-catalog-api

Customer-facing internal API for card catalog and metadata queries.

## Architecture

- Fargate service behind the shared ALB
- PostgreSQL database for card metadata storage
- ALB routes `/api/cards` and `/api/cards/*` to this service

## Modules Used

| Module | Purpose |
|--------|---------|
| `container` | Fargate API with ALB integration, autoscaling, alarms |
| `database` | PostgreSQL with Secrets Manager password, encryption |

## Deploy

```bash
cd live/dev/card-catalog-api
terragrunt init
terragrunt plan
terragrunt apply
```
