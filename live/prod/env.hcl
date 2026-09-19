# =============================================================================
# env.hcl — Production environment configuration
# =============================================================================

locals {
  environment = "prod"
  aws_region  = "us-east-1"
  account_id  = "333333333333"

  # Shared platform foundation outputs (prod)
  vpc_id              = "vpc-0prd000000000"
  private_subnet_ids  = ["subnet-0prd-priv-1", "subnet-0prd-priv-2"]
  data_subnet_ids     = ["subnet-0prd-data-1", "subnet-0prd-data-2"]
  ecs_cluster_arn     = "arn:aws:ecs:us-east-1:333333333333:cluster/shared-prod"
  alb_listener_arn      = "arn:aws:elasticloadbalancing:us-east-1:333333333333:listener/app/shared-prod-alb/abc123/def456"
  alb_security_group_id = "sg-0prd-alb-shared"
  alarm_sns_topic_arn   = "arn:aws:sns:us-east-1:333333333333:platform-alarms-prod"
}
