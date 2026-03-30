# ============================================================================
# Outputs – Lambda Module
# ============================================================================
# Output Summary Table:
# ----------------------------------------------------------------------------
# | Output Name                | Description                                               |
# |----------------------------|-----------------------------------------------------------|
# | lambda_function_arn        | Map of ARNs for all Lambda functions                     |
# | lambda_function_name       | Map of names for all Lambda functions                    |
# | lambda_role_arn            | Map of IAM Role ARNs associated with each Lambda function|
# | lambda_version_arn         | Map of versioned ARNs for Lambda functions               |
# | lambda_version             | Map of latest published Lambda versions                  |
# | lambda_qualified_arn       | Map of qualified ARNs including version (used in Lex / integrations) |
# | functions                  | Map of all Lambda functions with name and ARN            |
#
# Notes:
# - All outputs are provided as maps keyed by the Lambda function name.
# - `lambda_qualified_arn` is critical for services like Lex which require version-specific invocation.
# - `functions` provides a convenient summary of name + ARN for integration or reference.
# ============================================================================

# Lambda function ARN (map of all functions)
output "lambda_function_arn" {
  description = "ARNs of all Lambda functions"
  value       = { for k, v in aws_lambda_function.this : k => v.arn }
}

# Lambda function name
output "lambda_function_name" {
  description = "Names of all Lambda functions"
  value       = { for k, v in aws_lambda_function.this : k => v.function_name }
}

# Lambda IAM Role ARN
output "lambda_role_arn" {
  description = "IAM Role ARNs for all Lambda functions"
  value       = { for k, v in aws_iam_role.lambda_role : k => v.arn }
}

# Lambda function version ARN
output "lambda_version_arn" {
  description = "Versioned ARN of all Lambda functions"
  value       = { for k, v in aws_lambda_function.this : k => v.arn }
}

# Latest published version
output "lambda_version" {
  description = "Latest published Lambda versions"
  value       = { for k, v in aws_lambda_function.this : k => v.version }
}

# Versioned ARN (IMPORTANT for Lex / integrations)
output "lambda_qualified_arn" {
  description = "Qualified ARNs including version for all Lambda functions"
  value       = { for k, v in aws_lambda_function.this : k => v.qualified_arn }
}

# Generic functions output
output "functions" {
  description = "Map of all Lambda functions (name + ARN)"
  value = {
    for k, v in aws_lambda_function.this : k => {
      function_name = v.function_name
      arn           = v.arn
    }
  }
}

# output "dead_letter_queue_arn" {
#   description = "SQS ARN used as async failure DLQ when lambda_hardening is enabled"
#   value       = var.lambda_hardening && length(var.lambdas) > 0 ? aws_sqs_queue.lambda_dlq[0].arn : null
# }