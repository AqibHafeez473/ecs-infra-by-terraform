terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# ------------------------------------------------------------------------------
# Data Sources
# ------------------------------------------------------------------------------

data "aws_caller_identity" "current" {}

# ------------------------------------------------------------------------------
# S3 Bucket — Terraform State Storage
# ------------------------------------------------------------------------------

resource "aws_s3_bucket" "tf_state" {
  bucket = "${var.project_name}-tf-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name      = "${var.project_name}-tf-state"
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ------------------------------------------------------------------------------
# DynamoDB Table — State Locking
# ------------------------------------------------------------------------------

resource "aws_dynamodb_table" "tf_locks" {
  name         = "${var.project_name}-tf-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name      = "${var.project_name}-tf-locks"
    ManagedBy = "terraform"
    Project   = var.project_name
  }
}

# ------------------------------------------------------------------------------
# Outputs — copy these into main/backend.tf
# ------------------------------------------------------------------------------

output "s3_bucket_name" {
  description = "S3 bucket name — use in main/backend.tf"
  value       = aws_s3_bucket.tf_state.bucket
}

output "dynamodb_table_name" {
  description = "DynamoDB table name — use in main/backend.tf"
  value       = aws_dynamodb_table.tf_locks.name
}

output "aws_account_id" {
  description = "AWS Account ID"
  value       = data.aws_caller_identity.current.account_id
}
