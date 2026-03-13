# Architecture

## Overview

The Foundry service catalog standardizes three workload patterns on AWS for Fanatics Collectibles backend services. Each service consumes shared platform infrastructure and composes reusable Terraform modules.

## Architecture Diagram

```mermaid
graph TB
    subgraph Internet
        Users["Clients / Internal Services"]
    end

    subgraph AWS["AWS Account"]
        subgraph VPC["Shared VPC (multi-AZ)"]
            subgraph Public["Public Subnets"]
                ALB["Application Load Balancer<br/>(HTTPS termination)"]
            end

            subgraph Private["Private Subnets"]
                subgraph ECS["Shared ECS Cluster (Fargate)"]
                    CCA["card-catalog-api<br/>(ECS Service)"]
                    MFG["manufacturing-orchestrator<br/>(ECS Worker)"]
                end

                Lambda["orders-ingestion<br/>(Lambda)"]
            end

            subgraph Data["Data Subnets"]
                RDS["PostgreSQL RDS<br/>(card_catalog)"]
            end
        end

        SQS_Orders["SQS: order-events<br/>+ DLQ"]
        SQS_Mfg["SQS: manufacturing-jobs<br/>+ DLQ"]

        CW["CloudWatch<br/>Logs & Alarms"]
        SM["Secrets Manager"]
        IAM["IAM Roles<br/>(least privilege)"]
        SNS["SNS Alarm Topic"]
    end

    Users -->|HTTPS| ALB
    ALB -->|/api/cards/*| CCA
    CCA -->|port 5432| RDS
    CCA -.->|reads| SM

    Users -->|"Publish order events"| SQS_Orders
    SQS_Orders -->|"Event source mapping"| Lambda

    SQS_Mfg -->|"Long-poll"| MFG

    CCA -->|logs| CW
    MFG -->|logs| CW
    Lambda -->|logs| CW
    CW -->|alarms| SNS

    style ALB fill:#f9a825
    style RDS fill:#1565c0,color:#fff
    style SQS_Orders fill:#e65100,color:#fff
    style SQS_Mfg fill:#e65100,color:#fff
    style Lambda fill:#7b1fa2,color:#fff
    style CCA fill:#2e7d32,color:#fff
    style MFG fill:#2e7d32,color:#fff
```

## Traffic Flow

### card-catalog-api (ECS API)
1. Clients send HTTPS requests to the shared ALB.
2. ALB listener rule routes `/api/cards/*` to the card-catalog-api target group.
3. ECS Fargate tasks in private subnets handle requests.
4. Application reads/writes to PostgreSQL RDS in data subnets.
5. DB credentials are retrieved from Secrets Manager (managed via `manage_master_user_password`).

### orders-ingestion (Lambda)
1. Upstream producers send order events to the `order-events` SQS queue.
2. Lambda event source mapping polls the queue in batches of 5.
3. Lambda processes each message; failures are reported via `ReportBatchItemFailures`.
4. Messages that fail 3 times are routed to the dead-letter queue.

### manufacturing-orchestrator (ECS Worker)
1. Manufacturing job messages arrive in the `manufacturing-jobs` SQS queue.
2. ECS Fargate worker tasks long-poll the queue using the AWS SDK.
3. Workers process jobs with a 300-second visibility timeout for long-running tasks.
4. Failed messages follow the same DLQ pattern after 3 retries.

## Trust Boundaries

| Boundary | Control |
|----------|---------|
| Internet → ALB | HTTPS termination, security groups |
| ALB → ECS tasks | Private subnets, security group ingress rules |
| ECS/Lambda → RDS | Security group-to-security group ingress, private data subnets |
| ECS/Lambda → SQS | IAM policies scoped to specific queue ARNs |
| ECS/Lambda → Secrets Manager | IAM policies scoped to specific secret ARNs |
| All compute | No public IP assignment, outbound-only internet via NAT Gateway |

## Shared Platform Foundation (assumed to exist)

The following resources are managed by a separate platform team and consumed as inputs:

- VPC with public, private, and data subnets across 2+ AZs
- ECS Fargate cluster
- ALB with HTTPS listener
- SNS topic for alarm notifications
- KMS keys for encryption
- NAT Gateway for outbound internet access
