# ============================================================================
# ────────────────────────────── LEX BOT, LAMBDAS AND LOG GROUPS ──────────────────────────────
# ============================================================================
# Resource Summary:
# ----------------------------------------------------------------------------
# | Resource Type                | Name               | Purpose                                     |
# |------------------------------|------------------|--------------------------------------------|
# | aws_cloudwatch_log_group     | lex_logs          | Log group for Lex bot                        |
# | aws_cloudwatch_log_group     | lambda_logs       | Dynamic log groups for each Lambda          |
# | aws_lambda_function          | lambda.functions  | Lambda functions for intent fulfillment     |
# | lexv2_bot                    | lex_bot           | Main Lex V2 bot                              |
#
# Behavior:
# - Creates Lex log group and dynamic Lambda log groups
# - Deploys Lambda functions for intents with fulfillment_lambda_name
# - Exposes maps of Lambda functions and log group ARNs
# - Lex bot depends on Lambdas (ensuring Lambda exists before deployment)
# ============================================================================

# Lex Bot
output "lex_bot_id" {
  description = "The ID of the Lex bot"
  value       = module.lex.bot_id
}

output "lex_bot_arn" {
  description = "The ARN of the Lex bot"
  value       = module.lex.bot_arn
}

output "lex_cloudwatch_log_group_arn" {
  description = "The ARN of the Lex CloudWatch log group"
  value       = module.lex_logs.log_group_arn
}

# Lambda Functions
output "lambda_functions" {
  description = "Map of Lambda function names to their ARNs"
  value       = { for k, v in module.lambda.functions : k => v.arn }
}

output "lambda_cloudwatch_log_group_arns" {
  description = "Map of Lambda log group ARNs"
  value       = { for k, v in module.lambda_logs : k => v.log_group_arn }
}