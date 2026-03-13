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

  container_image  = "111111111111.dkr.ecr.us-east-1.amazonaws.com/card-catalog-api:latest"
  cpu              = 256
  memory           = 512
  db_instance_class = "db.t4g.micro"
  db_multi_az       = false
}
