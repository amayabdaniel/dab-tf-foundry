# =============================================================================
# env.hcl — Staging environment configuration
# =============================================================================

locals {
  environment = "staging"
  aws_region  = "us-east-1"
  account_id  = "222222222222"

  # Shared platform foundation outputs (staging)
  vpc_id              = "vpc-0stg000000000"
  private_subnet_ids  = ["subnet-0stg-priv-1", "subnet-0stg-priv-2"]
  data_subnet_ids     = ["subnet-0stg-data-1", "subnet-0stg-data-2"]
  ecs_cluster_arn     = "arn:aws:ecs:us-east-1:222222222222:cluster/shared-staging"
  alb_listener_arn    = "arn:aws:elasticloadbalancing:us-east-1:222222222222:listener/app/shared-staging-alb/abc123/def456"
  alarm_sns_topic_arn = "arn:aws:sns:us-east-1:222222222222:platform-alarms-staging"
}
