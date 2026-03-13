# Migration & Refactor Plan

## Overview

This plan covers migrating existing, independently-maintained Terraform stacks to the Foundry service catalog modules. The approach is incremental — teams adopt one service at a time without a big-bang cutover.

## Phase 1: Inventory and Assessment

Before writing any Terraform, audit existing stacks:

1. **Catalog existing resources** per service: ECS services, task definitions, IAM roles, security groups, RDS instances, SQS queues, CloudWatch alarms.
2. **Map to catalog modules**: Identify which Foundry module covers each resource.
3. **Flag gaps**: Resources that don't fit any module (e.g., custom EventBridge rules, CloudFront distributions) remain in team-managed Terraform until new modules are built.
4. **Document state file locations**: Note the S3 bucket/key and DynamoDB table for each existing state.

## Phase 2: Import Existing Resources

Use Terraform `import` blocks (Terraform 1.5+) to bring existing resources under catalog module management without destroying and recreating them.

### Example: Importing an existing ECS service into the `container` module

```hcl
# In the new service composition (live/_components/card-catalog-api/main.tf)

import {
  to = module.api.aws_ecs_service.this
  id = "main-cluster/card-catalog-api-prod"
}

import {
  to = module.api.aws_ecs_task_definition.this
  id = "card-catalog-api-prod"
}

import {
  to = module.api.aws_cloudwatch_log_group.this
  id = "/ecs/card-catalog-api-prod"
}

import {
  to = module.api.aws_security_group.tasks
  id = "sg-0abc123def456789"
}

import {
  to = module.api.aws_iam_role.task
  id = "card-catalog-api-prod-task"
}

import {
  to = module.api.aws_iam_role.execution
  id = "card-catalog-api-prod-execution"
}
```

### Example: Importing an existing RDS instance into the `database` module

```hcl
import {
  to = module.database.aws_db_instance.this
  id = "card-catalog-db-prod"
}

import {
  to = module.database.aws_db_subnet_group.this
  id = "card-catalog-db-prod"
}

import {
  to = module.database.aws_security_group.this
  id = "sg-0def456abc789012"
}
```

### Example: Importing an existing SQS queue into the `queue` module

```hcl
import {
  to = module.order_queue.aws_sqs_queue.this
  id = "https://sqs.us-east-1.amazonaws.com/123456789012/orders-ingestion-prod"
}

import {
  to = module.order_queue.aws_sqs_queue.dlq
  id = "https://sqs.us-east-1.amazonaws.com/123456789012/orders-ingestion-prod-dlq"
}
```

## Phase 3: Use `moved` Blocks for Refactors

When restructuring Terraform (e.g., renaming modules or splitting compositions), use `moved` blocks to avoid destroy/recreate cycles:

```hcl
# Renaming module.ecs_api to module.api
moved {
  from = module.ecs_api
  to   = module.api
}

# Renaming module.rds to module.database
moved {
  from = module.rds
  to   = module.database
}
```

## Phase 4: State Migration with `terraform state mv`

For resources that need to move between state files (e.g., from a monolithic state to per-service state):

```bash
# Move ECS resources from the old monolith state to the new per-service state
terraform state mv \
  -state=terraform.tfstate \
  -state-out=card-catalog-api.tfstate \
  'module.ecs_services["card-catalog-api"]' \
  'module.api'

# Move RDS resources
terraform state mv \
  -state=terraform.tfstate \
  -state-out=card-catalog-api.tfstate \
  'aws_db_instance.card_catalog' \
  'module.database.aws_db_instance.this'
```

## Phase 5: Rollout Sequence

Migrate services in order of risk, lowest first:

### Wave 1: Non-production environments (Week 1-2)
1. Deploy `card-catalog-api` in **dev** using catalog modules with `import` blocks.
2. Run `terraform plan` — confirm zero changes (import matched existing resources).
3. Run `terraform apply` to adopt state.
4. Repeat for `orders-ingestion` and `manufacturing-orchestrator` in dev.

### Wave 2: Staging validation (Week 3)
1. Repeat Wave 1 for staging.
2. Run integration tests against staging to confirm no behavioral changes.
3. Validate CloudWatch alarms fire correctly (trigger a test alarm).

### Wave 3: Production migration (Week 4-5)
1. Schedule migration during low-traffic window.
2. Import one service at a time with `terraform plan` review.
3. Keep old Terraform state as backup (copy S3 object before migration).
4. Monitor dashboards and alarms for 24 hours post-migration.

### Wave 4: Cleanup (Week 6)
1. Remove `import` blocks (only needed for initial import).
2. Remove `moved` blocks after one full apply cycle.
3. Archive old Terraform code repositories.
4. Update CI/CD pipelines to use new state file locations.

## Rollback Strategy

- **Before apply**: Abort and keep existing infrastructure untouched.
- **After apply with import**: Resources are now managed by new Terraform. To rollback, use `terraform state rm` to remove from new state, then re-import into old Terraform.
- **State backups**: Always copy the S3 state object before any migration step.

## Risks and Mitigations

| Risk | Mitigation |
|------|-----------|
| Import misses a resource | Run `terraform plan` and verify zero changes before applying |
| Naming convention mismatch | Use `terraform plan` to identify any rename-triggered replacements; adjust module inputs |
| State file corruption | S3 versioning on state bucket; copy state before migration |
| Downtime during migration | Import-based migration is non-destructive — no resources are recreated |
| Teams unfamiliar with new modules | Pair with platform team during Wave 1; create runbook for common operations |
