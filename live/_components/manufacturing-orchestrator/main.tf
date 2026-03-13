# =============================================================================
# manufacturing-orchestrator
#
# Fargate worker that consumes manufacturing jobs from SQS.
# No public load balancer — runs as a background processor.
#
# In production, module sources would reference a git tag or private registry:
#   source = "git::https://github.com/fanatics/dab-tf-foundry.git//modules/container?ref=v1.0.0"
# =============================================================================

# -- SQS queue for manufacturing jobs --
module "job_queue" {
  source = "../../../modules/queue"

  queue_name                 = "manufacturing-jobs"
  environment                = var.environment
  visibility_timeout_seconds = 300    # Workers may take several minutes per job
  message_retention_seconds  = 604800 # 7 days
  max_receive_count          = 3

  alarm_actions = [var.alarm_sns_topic_arn]
}

# -- Worker service (no ALB) --
module "worker" {
  source = "../../../modules/container"

  service_name = "mfg-orchestrator"
  environment  = var.environment
  cluster_arn  = var.ecs_cluster_arn
  vpc_id       = var.vpc_id
  subnet_ids   = var.private_subnet_ids

  container_image = var.container_image
  container_port  = 8080
  cpu             = var.cpu
  memory          = var.memory

  # No ALB — this is a background worker
  enable_load_balancer = false

  desired_count = 2
  min_count     = 1
  max_count     = 6

  environment_variables = {
    SERVICE_NAME  = "manufacturing-orchestrator"
    SQS_QUEUE_URL = module.job_queue.queue_url
    SQS_QUEUE_ARN = module.job_queue.queue_arn
    WORKER_MODE   = "true"
  }

  # Grant the worker permission to consume from the queue
  additional_task_policy_statements = [
    {
      effect = "Allow"
      actions = [
        "sqs:ReceiveMessage",
        "sqs:DeleteMessage",
        "sqs:GetQueueAttributes",
        "sqs:ChangeMessageVisibility",
      ]
      resources = [module.job_queue.queue_arn]
    }
  ]

  alarm_actions = [var.alarm_sns_topic_arn]
}

# -- Observability --
module "observability" {
  source = "../../../modules/observability"

  service_name = "manufacturing-orchestrator"
  environment  = var.environment
  service_type = "worker"

  log_group_name   = module.worker.log_group_name
  ecs_cluster_name = split("/", var.ecs_cluster_arn)[1]
  ecs_service_name = module.worker.service_name
  sqs_queue_name   = module.job_queue.queue_name
  dlq_queue_name   = module.job_queue.dlq_name
  alarm_arns       = concat(module.worker.alarm_arns, module.job_queue.alarm_arns)
  alarm_actions    = [var.alarm_sns_topic_arn]
}

# NOTE: Queue-depth based autoscaling is a planned future enhancement.
# Currently the worker scales on CPU/memory utilization. For queue-depth
# scaling, an appautoscaling policy targeting ApproximateNumberOfMessagesVisible
# would replace or supplement the CPU/memory policies in the container module.
