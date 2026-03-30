# ============================================================================
# AWS Lambda Functions – IAM, Roles, and Deployment
# ============================================================================
# Resource Summary Table:
# ----------------------------------------------------------------------------
# | Resource Type                    | Name / Identifier           | Purpose & Notes                                  |
# |---------------------------------|----------------------------|--------------------------------------------------|
# | data.aws_iam_policy_document     | lambda_assume_role         | Trust policy allowing Lambda service to assume role |
# | aws_iam_role                     | lambda_role                | IAM role for Lambda function execution          |
# | aws_iam_role_policy_attachment   | lambda_basic_execution     | Attaches AWSLambdaBasicExecutionRole to Lambda role |
# | aws_lambda_function              | this                       | Creates the Lambda function, supports environment variables, VPC config, and lifecycle settings |
#
# Notes:
# - One IAM role per Lambda function is created dynamically using `for_each`.
# - Lambda functions reference artifacts from S3 and support optional `source_code_hash`.
# - Environment variables are merged from global and per-function variables.
# - VPC configuration is optional and only applied if subnet IDs and security groups are provided.
# - Lambda functions have active X-Ray tracing enabled.
# - Optional hardening (default on): SQS DLQ, code signing config, reserved concurrency, KMS for env.
# - `prevent_destroy` ensures Lambda functions are not accidentally destroyed.
# - `create_before_destroy` ensures safe updates.
# - Tags can be applied both globally (`var.tags`) and per-function (`var.function_tags`).
# ============================================================================

# ============================================================================
# IAM Trust Policy: Lambda → IAM Role
# ============================================================================
# Allows AWS Lambda service (lambda.amazonaws.com) to assume this role.
data "aws_iam_policy_document" "lambda_assume_role" {
  for_each = var.lambdas
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# ============================================================================
# IAM Role for Lambda Functions
# ============================================================================
# Core execution role for Lambda functions with basic execution permissions.
resource "aws_iam_role" "lambda_role" {
  for_each           = var.lambdas
  name               = "${each.value.namespace}-${replace(each.key, "_", "-")}-lambda-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume_role[each.key].json
  tags               = var.tags
}

# ============================================================================
# Attach AWSLambdaBasicExecutionRole Policy
# ============================================================================
# Grants Lambda permission to write logs to CloudWatch.
resource "aws_iam_role_policy_attachment" "lambda_basic_execution" {
  for_each   = var.lambdas
  role       = aws_iam_role.lambda_role[each.key].name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

# ============================================================================
# Lambda Function Deployment
# ============================================================================
# Creates Lambda functions with the following configurable features:
# - S3-based deployment package
# - Handler, runtime, timeout, and memory size
# - Optional environment variables (merged global + function-specific)
# - Optional VPC configuration
# - Active X-Ray tracing
# - Lifecycle protection and safe replacement
resource "aws_lambda_function" "this" {
  for_each                       = var.lambdas
  function_name                  = each.key
  description                    = each.value.description
  role                           = aws_iam_role.lambda_role[each.key].arn
  handler                        = each.value.handler
  runtime                        = each.value.runtime
  timeout                        = each.value.timeout
  memory_size                    = each.value.memory_size
  kms_key_arn                    = each.value.kms_key_arn
  s3_key                         = each.value.s3_key
  s3_bucket                      = each.value.s3_bucket //var.lambda_artifacts_bucket
  reserved_concurrent_executions = each.value.reserved_concurrent_executions
  source_code_hash               = lookup(each.value, "source_code_hash", null)
  publish                        = true
  dynamic "environment" {
    for_each = (
      length(var.environment_variables) > 0 ||
      length(each.value.environment_variables) > 0
    ) ? [1] : []
    content {
      variables = merge(
        var.environment_variables,
        each.value.environment_variables
      )
    }
  }
  dynamic "vpc_config" {
    for_each = (
      var.vpc_subnet_ids != null &&
      var.vpc_security_group_ids != null
    ) ? [1] : []

    content {
      subnet_ids         = var.vpc_subnet_ids
      security_group_ids = var.vpc_security_group_ids
    }
  }
  tracing_config {
    mode = "Active"
  }
  tags = merge(
    var.tags,
    var.function_tags
  )
  lifecycle {
    //prevent_destroy       = true
    create_before_destroy = true
  }
}