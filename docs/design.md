# Service Catalog Design Document

## Goals

The Foundry service catalog exists to solve a specific problem: multiple engineering teams at Fanatics Collectibles maintain independent Terraform stacks with duplicated patterns for common workloads. This duplication leads to inconsistent security posture, divergent operational practices, and wasted engineering time re-solving the same infrastructure problems.

The catalog provides:

1. **Standardized modules** with opinionated defaults for security, observability, and networking.
2. **Reduced cognitive load** — teams compose modules rather than wiring AWS resources from scratch.
3. **Consistent guardrails** — encryption, IAM, tagging, and alarms are built into every module.
4. **Clear ownership boundaries** — the platform team owns modules; application teams own service compositions.

## Module Taxonomy

The catalog uses a four-layer taxonomy:

### Layer 1: Shared Foundation (out of scope)
Platform-managed resources consumed as inputs: VPC, subnets, ECS cluster, ALB, KMS, SNS alarm topic. These are managed by the platform team in a separate Terraform state and exposed via remote state outputs or parameter store.

### Layer 2: Capability Modules
Infrastructure building blocks that provide a single AWS capability with secure defaults:

| Module | Capability |
|--------|-----------|
| `queue` | SQS queue + DLQ, encryption, redrive policy, DLQ alarm |
| `database` | PostgreSQL RDS, Secrets Manager password, encryption, backups, alarms |

### Layer 3: Workload Modules
Compute patterns that deploy a running service:

| Module | Pattern |
|--------|---------|
| `container` | Fargate service — API (ALB-backed) or worker (no ALB) |
| `function` | Event-driven Lambda with optional SQS trigger |

### Layer 3.5: Platform Modules
Cross-cutting concerns that apply to any workload type:

| Module | Capability |
|--------|-----------|
| `observability` | CloudWatch dashboard, log metric filters, composite alarm per service |
| `guardrails` | AWS Config rules, IAM permissions boundary, budget alerts per environment |

### Layer 4: Service Compositions (`live/`)
Application teams compose capability and workload modules into deployable services. Each composition lives in its own directory with its own state, variables, and backend configuration. This is where teams express service-specific decisions (container image, scaling limits, database size) while inheriting platform standards from the modules.

## Platform Boundaries and Ownership

| Concern | Owner | Mechanism |
|---------|-------|-----------|
| VPC, subnets, ECS cluster, ALB | Platform team | Separate Terraform state |
| Module library (`modules/`) | Platform team | Versioned releases, PR review |
| Service compositions (`live/`) | Application teams | Own Terraform state per service |
| Container images | Application teams | CI/CD pipelines, ECR |

The `modules/` directory is treated as a standalone library. In production, it would be a separate Git repository published to a private Terraform registry. Application teams pin module versions and upgrade on their own schedule.

## Standards

### Naming
All resources follow `{service_name}-{environment}` naming. This convention is enforced inside modules via `local.name_prefix`. Service names are validated to be lowercase alphanumeric with hyphens.

### Tagging
Every module merges a standard tag set with user-provided tags:

```hcl
{
  Service     = var.service_name
  Environment = var.environment
  ManagedBy   = "terraform"
  Module      = "container"  # module identity
}
```

Teams can add project-specific tags. Provider-level `default_tags` in service compositions add team and project tags.

### Variables
- All variables are strongly typed with descriptions.
- Validation blocks enforce constraints (e.g., environment must be `dev`, `staging`, or `prod`).
- Sensible defaults reduce boilerplate — a team can deploy a working service with minimal inputs.
- Optional features use boolean toggles or null defaults rather than separate modules.

### Versioning
In production, modules would be versioned with Git tags (e.g., `v1.0.0`) and consumed via:
```hcl
source = "git::https://github.com/fanatics/dab-tf-foundry.git//modules/container?ref=v1.2.0"
```

Teams pin to specific versions and upgrade explicitly. Breaking changes follow semver.

### Environments
Environment is a first-class input to every module. It affects:
- Resource naming
- Tagging
- RDS final snapshot behavior (skipped in dev, required in prod)
- Log levels in application code

## Security Model

### IAM
- **Least privilege**: Each module creates purpose-built IAM roles.
- **ECS**: Separate execution role (pulls images, reads secrets) and task role (application permissions).
- **Lambda**: Single execution role with only the permissions needed (basic execution + SQS if configured).
- **Extensible**: `additional_task_policy_statements` / `additional_policy_statements` allow teams to add permissions without modifying the module.
- **No wildcard resources** except ECS Exec SSM permissions (required by AWS).

### Encryption
- RDS: `storage_encrypted = true` (default).
- SQS: SQS-managed SSE by default, with optional KMS key override.
- CloudWatch Logs: Encrypted by default in AWS.
- Secrets Manager: Manages RDS master password — never in Terraform state.

### Network Isolation
- All compute runs in private subnets with no public IP.
- RDS is in dedicated data subnets, not publicly accessible.
- Security groups use ingress rules scoped to specific ports and source security groups.
- Outbound internet access via NAT Gateway (managed by platform team).

## Secrets Handling

The catalog avoids plaintext secrets in Terraform:

1. **RDS passwords**: `manage_master_user_password = true` delegates password lifecycle to Secrets Manager.
2. **ECS secrets injection**: The `secrets` variable accepts Secrets Manager or SSM ARNs. The execution role is granted read access to those specific ARNs.
3. **Lambda**: Environment variables for non-sensitive config; Secrets Manager SDK calls for sensitive values.

## Consumption Patterns

Service deployments use Terragrunt to eliminate boilerplate across environments.

### New Service Onboarding
1. Create a Terraform composition in `live/_components/{service-name}/` that composes catalog modules.
2. Create a `terragrunt.hcl` in each environment directory (`live/{env}/{service-name}/`) pointing to the component.
3. Set service-specific and environment-specific inputs in the `terragrunt.hcl`.
4. Run `terragrunt init && terragrunt plan` to validate.

### Environment Promotion
Terragrunt makes environment promotion trivial — the same component Terraform is used for every environment. Only the inputs differ:
```bash
cd live/dev/card-catalog-api && terragrunt plan    # dev with db.t4g.micro
cd live/prod/card-catalog-api && terragrunt plan   # prod with db.t4g.medium, Multi-AZ
```

### Upgrading Modules
1. Platform team releases a new module version with a changelog.
2. Application team updates the `ref=` tag in their component's module source.
3. Run `terragrunt plan` in each environment to review changes.
4. Apply in dev → staging → prod.

## How This Reduces Duplication

Before the catalog, each team independently implemented:
- ECS task definitions, services, IAM roles, security groups
- RDS instances with varying security configurations
- SQS queues without consistent DLQ patterns
- CloudWatch log groups with inconsistent retention
- Alarms (if any) with varying thresholds

After adoption, teams write ~50 lines of Terraform to compose a production-ready service instead of ~300+ lines of raw resource definitions. Security, observability, and operational standards are inherited automatically.
