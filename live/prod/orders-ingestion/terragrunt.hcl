include "root" {
  path = find_in_parent_folders("root.hcl")
}

locals {
  env = read_terragrunt_config(find_in_parent_folders("env.hcl"))
}

terraform {
  source = "${get_repo_root()}/live/_components/orders-ingestion"
}

inputs = {
  alarm_sns_topic_arn            = local.env.locals.alarm_sns_topic_arn
  reserved_concurrent_executions = 50
}
