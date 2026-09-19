# =============================================================================
# card-catalog-api
#
# Customer-facing internal API for card catalog and metadata queries.
# Fargate service behind the shared ALB, backed by PostgreSQL.
#
# In production, module sources would reference a git tag or private registry:
#   source = "git::https://github.com/fanatics/dab-tf-foundry.git//modules/container?ref=v1.0.0"
# =============================================================================

module "api" {
  source = "../../../modules/container"

  service_name = "card-catalog-api"
  environment  = var.environment
  cluster_arn  = var.ecs_cluster_arn
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  container_image = var.container_image
  container_port  = var.container_port
  cpu             = var.cpu
  memory          = var.memory

  enable_load_balancer   = true
  listener_arn           = var.alb_listener_arn
  listener_rule_priority = 100
  path_patterns          = ["/api/cards", "/api/cards/*"]
  alb_security_group_id  = var.alb_security_group_id

  health_check_path = "/health"
  desired_count     = 2
  min_count         = 2
  max_count         = 8

  environment_variables = {
    SERVICE_NAME = "card-catalog-api"
    DB_HOST      = module.database.address
    DB_PORT      = tostring(module.database.port)
    DB_NAME      = "card_catalog"
  }

  secrets = {
    DB_SECRET_ARN = module.database.secret_arn
  }

  alarm_actions = [var.alarm_sns_topic_arn]
}

module "observability" {
  source = "../../../modules/observability"

  service_name = "card-catalog-api"
  environment  = var.environment
  service_type = "container"

  log_group_name         = module.api.log_group_name
  ecs_cluster_name       = split("/", var.ecs_cluster_arn)[1]
  ecs_service_name       = module.api.service_name
  db_instance_identifier = module.database.identifier
  alarm_arns             = concat(module.api.alarm_arns, module.database.alarm_arns)
  alarm_actions          = [var.alarm_sns_topic_arn]
}

module "database" {
  source = "../../../modules/database"

  identifier                 = "card-catalog"
  environment                = var.environment
  vpc_id                     = var.vpc_id
  subnet_ids                 = var.data_subnet_ids
  allowed_security_group_ids = [module.api.security_group_id]

  instance_class        = var.db_instance_class
  allocated_storage     = 20
  max_allocated_storage = 100
  db_name               = "card_catalog"
  multi_az              = var.db_multi_az

  alarm_actions = [var.alarm_sns_topic_arn]
}
