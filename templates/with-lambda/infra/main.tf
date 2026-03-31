# ============================================================================
# ────────────────────────────── CLOUDWATCH LOG GROUPS ──────────────────────────────
# ============================================================================
# Resource Summary:
# ----------------------------------------------------------------------------
# | Resource Type                | Name                | Purpose                                     |
# |------------------------------|-------------------|--------------------------------------------|
# | aws_cloudwatch_log_group     | lex_logs           | Log group for Lex bot                        |
# | aws_cloudwatch_log_group     | lambda_logs        | Dynamic log groups for each Lambda          |
#
# Behavior:
# - Creates a single Lex log group and dynamic Lambda log groups
# - Supports retention_in_days and optional prevent_destroy
# ============================================================================

# Lex logs (single log group)
module "lex_logs" {
  source            = "../../../modules/cloudwatch-log-group"
  name              = "/aws/lex/${local.bot_name}"
  retention_in_days = 365
  prevent_destroy   = var.environment == "prod"
}

# Lambda logs (dynamic log groups for each Lambda)
module "lambda_logs" {
  source   = "../../../modules/cloudwatch-log-group"
  for_each = local.lambdas

  name              = "/aws/lambda/${each.key}"
  retention_in_days = 365
  prevent_destroy   = var.environment == "prod"
}

# ============================================================================
# ────────────────────────────── LAMBDAS ──────────────────────────────
# ============================================================================
# Resource Summary:
# ----------------------------------------------------------------------------
# | Resource Type                | Name    | Purpose                                 |
# |------------------------------|--------|-----------------------------------------|
# | aws_lambda_function           | dynamic | Creates Lambda for each intent requiring a function |
#
# Behavior:
# - Loops through local.lambdas and deploys each Lambda
# - Attaches CloudWatch log group ARN per Lambda
# ============================================================================

module "lambda" {
  source                  = "../../../modules/lambda"
  lambdas                 = local.lambdas
  prevent_destroy         = var.environment == "prod"
  lambda_artifacts_bucket = var.s3_bucket

  lambda_log_group_arns = {
    for k, v in module.lambda_logs : k => v.log_group_arn
  }
}

# ============================================================================
# ────────────────────────────── LEX BOT ──────────────────────────────
# ============================================================================
# Resource Summary:
# ----------------------------------------------------------------------------
# | Resource Type                | Name    | Purpose                                 |
# |------------------------------|--------|-----------------------------------------|
# | aws_lexv2_bot                | lex    | Creates Lex bot using bot_config        |
#
# Behavior:
# - Integrates deployed Lambda functions with Lex
# - Depends on Lambda module to ensure functions exist before Lex creation
# ============================================================================

module "lex" {
  source = "../../../modules/lexv2models"

  bot_config = local.bot_config

  # Provide Lambda function info for Lex integration
  lambda_functions = {
    for k, v in module.lambda.functions : k => {
      function_name = v.function_name
      arn           = v.arn
    }
  }

  cloudwatch_log_group_arn = module.lex_logs.log_group_arn
  polly_arn                = local.polly_arn
  lexv2_bot_role_name      = "${local.namespace}-lex-iam-role"

  depends_on = [module.lambda] # Ensure Lambdas exist first
}