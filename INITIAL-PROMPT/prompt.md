Build a Terraform AWS service catalog for a sports collectibles company (Fanatics Collectibles). The company has 3 backend services with duplicated Terraform patterns that need unifying.

REPO STRUCTURE:
- `modules/` — reusable module library (as if separate repo)
- `live/_components/` — Terraform compositions that compose modules into deployable services
- `live/{dev,staging,prod}/` — Terragrunt per-environment configs
- `docs/` — all documentation

MODULES TO BUILD (use agnostic names, not aws-specific):
1. `container` — ECS Fargate service, supports API mode (ALB) and worker mode (no ALB). Circuit breaker, autoscaling, ECS Exec, CloudWatch alarms, secrets injection.
2. `function` — Lambda with optional SQS trigger, ReportBatchItemFailures, reserved concurrency, error/throttle alarms.
3. `queue` — SQS + DLQ, redrive policy, encryption, DLQ depth alarm.
4. `database` — PostgreSQL RDS, manage_master_user_password=true, gp3, encryption, Performance Insights, CPU/storage/connection alarms.
5. `observability` — CloudWatch dashboard (use templatefile with .tftpl to avoid Terraform 1.14 tuple type issues), log metric filter for errors, composite alarm aggregating child alarms.
6. `guardrails` — AWS Config rules (required tags, RDS encryption/no-public/backups, ECS awsvpc, log retention, SQS encryption), IAM permissions boundary, AWS Budgets per environment.

Every module must output `alarm_arns` for composite alarm integration.

EXAMPLE SERVICES (in live/_components/):
1. `card-catalog-api` — container (API mode) + database + observability
2. `orders-ingestion` — queue + function + observability (include src/handler.py with ReportBatchItemFailures pattern)
3. `manufacturing-orchestrator` — queue + container (worker mode) + observability

TERRAGRUNT:
- `live/root.hcl` — S3 backend generation, AWS provider with default_tags, reads env.hcl
- `live/{dev,staging,prod}/env.hcl` — environment-specific values (region, account_id, VPC, subnets, ECS cluster ARN, ALB listener ARN, SNS topic ARN)
- `live/{env}/{service}/terragrunt.hcl` — points to component, supplies env-specific inputs (dev=small, prod=large+multi_az)

DOCUMENTATION:
1. `docs/architecture.md` — Mermaid diagram: Internet→ALB→card-catalog-api(Fargate)→PostgreSQL, Order events→SQS→orders-ingestion(Lambda), Manufacturing jobs→SQS→manufacturing-orchestrator(Fargate Worker). Show trust boundaries, private/data subnets.
2. `docs/design.md` — 2-4 pages covering module taxonomy (Foundation→Capability→Workload→Platform→Composition), standards, security model, networking, Terragrunt consumption patterns.
3. `docs/migration-plan.md` — terraform import blocks, moved blocks, terraform state mv, phased rollout sequence.
4. `docs/operations-guardrails.md` — resilience/scaling, security/IAM, observability standards, cost governance, dev vs prod comparison table.
5. `docs/assumptions-tradeoffs-future.md` — ~8 assumptions, ~7 tradeoffs, ~12 future enhancements.
6. `docs/ai-usage.md` — AI usage summary.

TESTING:
- Native Terraform tests (.tftest.hcl) for every module using mock_provider
- Variable validation tests (expect_failures for invalid inputs)
- Plan-level assertion tests (verify resource naming, attributes)
- `make test` target and CI workflow job

ALSO INCLUDE:
- `Makefile` with fmt, validate, modules-test, test targets
- `.github/workflows/terraform.yml` — matrix strategy validating all modules + components, separate test job
- `.gitignore` with .terragrunt-cache/, .terraform/, backend.tf, provider.tf

CONSTRAINTS:
- Terraform >= 1.6, AWS Provider ~> 6.0 (6.36.0), Archive Provider ~> 2.7
- Use `data.aws_region.current.id` not `.name` (deprecated in provider 6.x)
- Use templatefile for dashboard JSON (Terraform 1.14 rejects conditional expressions with different tuple lengths)
- All compute in private subnets, RDS in data subnets
- Encryption everywhere, least-privilege IAM, CloudWatch logging on everything
- Assume shared platform foundation exists (VPC, subnets, ECS cluster, ALB, SNS topic)

Single commit message: "feat: terraform service catalog and terragrunt deployments"
