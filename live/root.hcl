# =============================================================================
# root.hcl — Shared Terragrunt configuration for all service deployments
#
# Generates:
#   - S3 backend with DynamoDB locking (unique key per service/env)
#   - AWS provider with region and default_tags
# =============================================================================

locals {
  env_config = read_terragrunt_config(find_in_parent_folders("env.hcl"))

  environment = local.env_config.locals.environment
  aws_region  = local.env_config.locals.aws_region
  account_id  = local.env_config.locals.account_id

  # Derive a unique state key from the relative path: dev/card-catalog-api → dev/card-catalog-api
  relative_path = path_relative_to_include()
  state_key     = "${local.relative_path}/terraform.tfstate"
}

# -----------------------------------------------------------------------------
# Remote State — S3 + DynamoDB
# -----------------------------------------------------------------------------
remote_state {
  backend = "s3"
  generate = {
    path      = "backend.tf"
    if_exists = "overwrite_terragrunt"
  }
  config = {
    bucket         = "fanatics-terraform-state-${local.account_id}"
    key            = "dab-tf-foundry/${local.state_key}"
    region         = local.aws_region
    encrypt        = true
    dynamodb_table = "terraform-locks"
  }
}

# -----------------------------------------------------------------------------
# Provider — Generated into each service directory
# -----------------------------------------------------------------------------
generate "provider" {
  path      = "provider.tf"
  if_exists = "overwrite_terragrunt"
  contents  = <<-EOF
    provider "aws" {
      region = "${local.aws_region}"

      default_tags {
        tags = {
          Environment = "${local.environment}"
          ManagedBy   = "terragrunt"
        }
      }
    }
  EOF
}

# -----------------------------------------------------------------------------
# Common inputs — injected into every service
# -----------------------------------------------------------------------------
inputs = {
  environment = local.environment
}
