# database

Deploys a PostgreSQL RDS instance with secure defaults and operational guardrails.

## Features

- `manage_master_user_password = true` — password managed by Secrets Manager, never in Terraform state
- gp3 storage with optional autoscaling
- Encryption at rest enabled
- Not publicly accessible
- Configurable Multi-AZ and deletion protection
- Performance Insights enabled by default
- Slow query logging and pg_stat_statements
- Automated backups with configurable retention
- CPU, storage, and connection count alarms
- Standardized tagging

## Usage

```hcl
module "my_database" {
  source = "../../../modules/database"

  identifier                 = "my-service-db"
  environment                = "prod"
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.data_subnet_ids
  allowed_security_group_ids = [module.my_api.security_group_id]

  instance_class    = "db.t4g.small"
  allocated_storage = 20
  db_name           = "myservice"
  multi_az          = true

  alarm_actions = [var.alarm_sns_topic_arn]
}
```
