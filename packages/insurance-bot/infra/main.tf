terraform {
  required_version = ">= 1.5.0"
}


# ============================================================================
# ────────────────────────────── CLOUDWATCH LOG GROUPS ──────────────────────────────
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

module "lambda" {
  source                  = "../../../modules/lambda"
  lambdas                 = local.lambdas
  prevent_destroy         = var.environment == "prod"
  lambda_artifacts_bucket = var.s3_bucket # ✅ add this

  # Map each Lambda to its CloudWatch log group ARN
  lambda_log_group_arns = {
    for k, v in module.lambda_logs : k => v.log_group_arn
  }
}

# ============================================================================
# ────────────────────────────── LEX BOT ──────────────────────────────
# ============================================================================

module "lex" {
  source = "../../../modules/lexv2models"

  bot_config = local.bot_config

  # Provide Lambda function info for Lex
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