include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_repo_root()}/live/_components/manufacturing-orchestrator"
}

inputs = {
  vpc_id              = local.env.locals.vpc_id
  private_subnet_ids  = local.env.locals.private_subnet_ids
  ecs_cluster_arn     = local.env.locals.ecs_cluster_arn
  alarm_sns_topic_arn = local.env.locals.alarm_sns_topic_arn

  container_image = "333333333333.dkr.ecr.us-east-1.amazonaws.com/manufacturing-orchestrator:v1.0.0"
  cpu             = 1024
  memory          = 2048
}
