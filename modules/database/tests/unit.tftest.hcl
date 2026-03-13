# ------------------------------------------------------------------------------
# Unit tests for database module — variable validation
# ------------------------------------------------------------------------------

mock_provider "aws" {}

variables {
  identifier                 = "test-db"
  environment                = "dev"
  vpc_id                     = "vpc-00000000000000000"
  subnet_ids                 = ["subnet-00000000000000000", "subnet-11111111111111111"]
  allowed_security_group_ids = ["sg-00000000000000000"]
  db_name                    = "testdb"
}

run "reject_uppercase_identifier" {
  command = plan

  variables {
    identifier = "MyDatabase"
  }

  expect_failures = [var.identifier]
}

run "reject_invalid_environment" {
  command = plan

  variables {
    environment = "test"
  }

  expect_failures = [var.environment]
}

run "valid_configuration_creates_rds" {
  command = plan

  assert {
    condition     = aws_db_instance.this.identifier == "test-db-dev"
    error_message = "RDS identifier must follow {name}-{env} pattern."
  }

  assert {
    condition     = aws_db_instance.this.engine == "postgres"
    error_message = "Engine must be postgres."
  }

  assert {
    condition     = aws_db_instance.this.manage_master_user_password == true
    error_message = "Secrets Manager password management must be enabled."
  }
}
