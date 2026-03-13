# =============================================================================
# env.hcl — Dev environment configuration
# =============================================================================

locals {
  environment = "dev"
  aws_region  = "us-east-1"
  account_id  = "111111111111"

  # Shared platform foundation outputs (dev)
  vpc_id              = "vpc-0dev000000000"
  private_subnet_ids  = ["subnet-0dev-priv-1", "subnet-0dev-priv-2"]
  data_subnet_ids     = ["subnet-0dev-data-1", "subnet-0dev-data-2"]
  ecs_cluster_arn     = "arn:aws:ecs:us-east-1:111111111111:cluster/shared-dev"
  alb_listener_arn    = "arn:aws:elasticloadbalancing:us-east-1:111111111111:listener/app/shared-dev-alb/abc123/def456"
  alarm_sns_topic_arn = "arn:aws:sns:us-east-1:111111111111:platform-alarms-dev"
}
