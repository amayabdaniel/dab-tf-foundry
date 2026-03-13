include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_repo_root()}/live/_components/card-catalog-api"
}

inputs = {
  vpc_id              = local.env.locals.vpc_id
  private_subnet_ids  = local.env.locals.private_subnet_ids
  data_subnet_ids     = local.env.locals.data_subnet_ids
  ecs_cluster_arn     = local.env.locals.ecs_cluster_arn
  alb_listener_arn    = local.env.locals.alb_listener_arn
  alarm_sns_topic_arn = local.env.locals.alarm_sns_topic_arn

  container_image   = "333333333333.dkr.ecr.us-east-1.amazonaws.com/card-catalog-api:v1.2.0"
  cpu               = 1024
  memory            = 2048
  db_instance_class = "db.t4g.medium"
  db_multi_az       = true
}
