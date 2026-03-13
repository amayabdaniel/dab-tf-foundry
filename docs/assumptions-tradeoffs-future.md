# Assumptions, Tradeoffs & Future Enhancements

## Assumptions

1. **Shared platform foundation exists**: VPC, subnets (public, private, data), ECS cluster, ALB with HTTPS listener, SNS alarm topic, NAT Gateway, and KMS keys are managed by a separate platform team. This catalog builds on top of that foundation.

2. **Single AWS account per environment**: Each environment (dev, staging, prod) has its own AWS account or is isolated within a single account using naming conventions and tagging. Cross-account patterns are out of scope.

3. **Single region**: All services deploy to a single AWS region (us-east-1 by default). Multi-region is a future enhancement.

4. **ECR for container images**: Application teams push container images to ECR. The ECS execution role has pull access via the managed `AmazonECSTaskExecutionRolePolicy`.

5. **Fargate-only ECS**: EC2-backed ECS is not supported. Fargate simplifies capacity management and is appropriate for the workload sizes described.

6. **PostgreSQL is the default relational database**: The catalog provides a PostgreSQL module. MySQL or Aurora support would be separate modules.

7. **Teams use Terraform CLI or CI/CD pipelines**: The catalog does not prescribe a specific CI/CD tool. Teams run `terraform plan` and `terraform apply` through their existing pipelines.

8. **S3 + DynamoDB backend for state**: Production deployments use S3 remote state with DynamoDB locking. Backend configuration is commented out in examples and configured per-team.

## Tradeoffs

### Opinionated defaults over flexibility
**Decision**: Modules enforce specific patterns (e.g., Fargate only, circuit breaker always on, encryption always on) rather than exposing every option.
**Upside**: Consistent security posture and operational behavior across all services.
**Downside**: Teams with edge-case requirements may need to extend or fork modules.

### Single ECS module for API and worker patterns
**Decision**: `container` handles both ALB-backed APIs and non-ALB workers via the `enable_load_balancer` toggle.
**Upside**: Reduces module count; shared autoscaling, IAM, and logging logic.
**Downside**: The module has conditional complexity. A very large catalog might split these into `ecs_api` and `ecs_worker`.

### ZIP-based Lambda packaging
**Decision**: The `function` module accepts a pre-built ZIP file rather than owning the build process.
**Upside**: Teams can use any build tool (SAM, CDK, custom scripts). The module stays simple.
**Downside**: Teams must manage their own packaging and the `archive_file` data source.

### SQS-managed SSE over KMS
**Decision**: Queues use SQS-managed SSE by default instead of customer-managed KMS keys.
**Upside**: No KMS key management overhead, no cross-service key policy complexity.
**Downside**: Less control over key rotation and access auditing. KMS can be opted into via `kms_master_key_id`.

### manage_master_user_password over manual secrets
**Decision**: RDS uses `manage_master_user_password = true` so Secrets Manager owns the password lifecycle.
**Upside**: Password never appears in Terraform state. Automatic rotation is possible.
**Downside**: Applications must use the Secrets Manager SDK or ECS secrets injection to retrieve credentials at runtime.

### CPU/memory autoscaling over queue-depth scaling for workers
**Decision**: ECS workers scale on CPU/memory utilization, not SQS queue depth.
**Upside**: Simpler implementation, works for all workload types.
**Downside**: Queue-depth scaling would be more responsive for bursty queue processing. Documented as a future enhancement.

### Relative module paths for demonstration
**Decision**: Service compositions use `../../modules/` relative paths instead of Git URLs or a registry.
**Upside**: The repo is self-contained and works without network access.
**Downside**: In production, modules would be versioned via Git tags or a private registry.

## Future Enhancements

1. **Private Terraform registry** — Publish modules to a private registry (Terraform Cloud, Artifactory, or S3-backed) for versioned consumption with `source = "registry.internal/fanatics/container/aws"`.

2. **AWS Service Catalog product wrappers** — Wrap approved module compositions as AWS Service Catalog products for teams that prefer a portal-based provisioning experience.

3. **Policy as code** — Integrate OPA/Conftest, Sentinel, or Checkov to validate module inputs and plan output against organizational policies before apply.

4. **WAF for public APIs** — Add an optional AWS WAF WebACL association for ALB-backed services to protect against common web exploits.

5. **Queue-depth autoscaling** — Add an `appautoscaling` policy targeting `ApproximateNumberOfMessagesVisible` for ECS workers that consume SQS queues, enabling faster scale-out during message surges.

6. **X-Ray tracing integration** — Add distributed tracing via AWS X-Ray to the existing observability module for end-to-end request tracing across services.

7. **EventBridge / Step Functions support** — New workload modules for event-driven orchestration patterns beyond simple SQS-Lambda or SQS-ECS flows.

8. **Blue/green and canary deployments** — ECS deployment controller integration with CodeDeploy for traffic-shifting deployment strategies.

9. **Multi-region strategy** — Module support for deploying services across regions with Route 53 failover routing and cross-region RDS read replicas.

10. **Cost anomaly detection** — AWS Cost Anomaly Detection monitors per service tag, with alerts routed to the same SNS topic as operational alarms.

11. **Container image scanning** — ECR image scanning results as a gate in CI/CD before deployment.

12. **Automated drift detection** — Scheduled `terraform plan` runs that alert on infrastructure drift via CloudWatch Events and SNS notifications.
