# dab-tf-foundry

Terraform + Terragrunt AWS service catalog for Fanatics Collectibles backend services. Provides reusable, opinionated modules for common workload patterns with DRY environment promotion via Terragrunt.

## Repository Layout

```
.
├── modules/                                    # Shared module library (treat as separate repo)
│   ├── container/                              # Fargate — API or worker pattern
│   ├── function/                               # Lambda — event-driven microservices
│   ├── queue/                                  # SQS queue + DLQ
│   ├── database/                               # PostgreSQL RDS
│   ├── observability/                          # Dashboards, metric filters, composite alarms
│   └── guardrails/                             # Config rules, permissions boundary, budgets
│
├── live/
│   ├── root.hcl                                # Shared Terragrunt config (backend, provider)
│   ├── _components/                            # Terraform compositions (shared across envs)
│   │   ├── card-catalog-api/                   # container + database
│   │   ├── orders-ingestion/                   # function + queue
│   │   └── manufacturing-orchestrator/         # container + queue
│   │
│   ├── dev/
│   │   ├── env.hcl                             # Dev environment config
│   │   ├── card-catalog-api/terragrunt.hcl
│   │   ├── orders-ingestion/terragrunt.hcl
│   │   └── manufacturing-orchestrator/terragrunt.hcl
│   ├── staging/
│   │   ├── env.hcl
│   │   └── ...
│   └── prod/
│       ├── env.hcl
│       └── ...
│
├── docs/
│   ├── architecture.md
│   ├── design.md
│   ├── migration-plan.md
│   ├── operations-guardrails.md
│   ├── assumptions-tradeoffs-future.md
│   └── ai-usage.md
│
├── .github/workflows/terraform.yml
├── Makefile
└── .gitignore
```

**`modules/`** — Reusable module library. In production this would be a separate Git repo published to a private Terraform registry.

**`live/_components/`** — Terraform root modules that compose multiple catalog modules into a deployable service. Shared across all environments.

**`live/{dev,staging,prod}/`** — Per-environment Terragrunt configs. Each `terragrunt.hcl` points to a component and supplies environment-specific inputs. Terragrunt generates the backend and provider blocks via `root.hcl`.

## Architecture Summary

```
Internet → ALB → card-catalog-api (Fargate) → PostgreSQL (RDS)
Order events → SQS → orders-ingestion (Lambda)
Manufacturing jobs → SQS → manufacturing-orchestrator (Fargate Worker)
```

All compute runs in private subnets. RDS in data subnets. Encryption, least-privilege IAM, CloudWatch logging, and alarms are built into every module. See [docs/architecture.md](docs/architecture.md) for the full diagram.

## Module Catalog

| Module | Type | Description |
|--------|------|-------------|
| `container` | Workload | Fargate service — API (ALB-backed) or worker (no ALB). Circuit breaker, autoscaling, ECS Exec. |
| `function` | Workload | Event-driven Lambda with optional SQS trigger, reserved concurrency, error/throttle alarms. |
| `queue` | Capability | SQS queue + DLQ, encryption, redrive policy, DLQ alarm. |
| `database` | Capability | PostgreSQL RDS, Secrets Manager password, encryption, backups, CPU/storage/connection alarms. |
| `observability` | Platform | CloudWatch dashboard, log metric filters, composite alarm per service. |
| `guardrails` | Platform | AWS Config rules, IAM permissions boundary, budget alerts per environment. |

## Service Deployments

| Service | Pattern | Modules |
|---------|---------|---------|
| card-catalog-api | API + database | `container` + `database` |
| orders-ingestion | Event-driven Lambda | `function` + `queue` |
| manufacturing-orchestrator | Background worker | `container` + `queue` |

## Quick Start

```bash
# Format all Terraform files
make fmt

# Validate modules
make modules-validate

# Validate component compositions
make components-validate

# Validate everything
make validate

# Deploy a service via Terragrunt
cd live/dev/card-catalog-api
terragrunt init
terragrunt plan
terragrunt apply

# Deploy all services in an environment
cd live/dev
terragrunt run-all apply
```

## Terragrunt Configuration

| File | Purpose |
|------|---------|
| `live/root.hcl` | S3 backend generation, AWS provider generation, common inputs |
| `live/{env}/env.hcl` | Environment-specific values: region, account ID, VPC, subnets, cluster ARN |
| `live/{env}/{service}/terragrunt.hcl` | Service-specific inputs: container image, CPU, memory, scaling |

Environment promotion is just changing the directory — same component, different inputs:
```bash
cd live/dev/card-catalog-api && terragrunt plan    # dev
cd live/prod/card-catalog-api && terragrunt plan   # prod
```

## Key Assumptions

- A shared platform foundation exists (VPC, subnets, ECS cluster, ALB, SNS topic) and is managed separately.
- Single AWS region, single account per environment.
- Fargate-only (no EC2 launch type).
- Container images are pushed to ECR by application CI/CD pipelines.
- See [docs/assumptions-tradeoffs-future.md](docs/assumptions-tradeoffs-future.md) for the full list.

## Intentionally Out of Scope

- VPC, subnet, and ECS cluster provisioning (shared platform responsibility)
- CI/CD pipeline definitions (team-specific)
- Application code beyond the Lambda example handler
- Multi-region deployment
- AWS Service Catalog product wrappers (documented as future enhancement)

## How to Review This Submission

1. **Start with** [docs/design.md](docs/design.md) for the overall approach and module taxonomy.
2. **Review the architecture** in [docs/architecture.md](docs/architecture.md) for the Mermaid diagram and traffic flow.
3. **Read the modules** in `modules/` — each has a README, and the code is designed to be readable top-to-bottom.
4. **See how modules compose** in `live/_components/` — each service is ~50 lines of Terraform.
5. **See how Terragrunt wires environments** in `live/{dev,staging,prod}/` — DRY config, one `terragrunt.hcl` per service per env.
6. **Check operations** in [docs/operations-guardrails.md](docs/operations-guardrails.md).
7. **Review the migration plan** in [docs/migration-plan.md](docs/migration-plan.md).
8. **See tradeoffs** in [docs/assumptions-tradeoffs-future.md](docs/assumptions-tradeoffs-future.md).

## Requirements

- Terraform >= 1.6 (tested with 1.14.7)
- Terragrunt >= 0.99
- AWS Provider ~> 6.0 (latest: 6.36.0)
- Archive Provider ~> 2.7 (latest: 2.7.1)
