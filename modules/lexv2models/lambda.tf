# ============================================================================
# Lambda Permissions for AWS Lex
# ============================================================================
# Resource Summary Table:
# ----------------------------------------------------------------------------
# | Resource Type           | Name / Identifier       | Purpose & Notes                                  |
# |-------------------------|------------------------|--------------------------------------------------|
# | aws_lambda_permission   | this                   | Grants Lex permission to invoke Lambda functions |
#
# Notes:
# - Permissions are created dynamically for each Lambda function provided in var.lambda_functions.
# - statement_id ensures uniqueness per Lambda function.
# - principal is always lex.amazonaws.com to allow Lex to invoke the function.
# - source_arn restricts invocation to this Lex bot alias (CKV_AWS_364 / least privilege).
# - Fine-grained permissions are preferred over broad managed policies.
# ============================================================================

data "aws_caller_identity" "current" {}
data "aws_region" "current" {}

locals {
  lex_bot_alias_source_arn = format(
    "arn:aws:lex:%s:%s:bot-alias/%s/%s",
    data.aws_region.current.id,
    data.aws_caller_identity.current.account_id,
    aws_lexv2models_bot.this.id,
    var.lex_bot_alias_id
  )
}

resource "aws_lambda_permission" "this" {
  for_each = var.lambda_functions

  statement_id  = "AllowLexInvoke-${each.key}"
  action        = "lambda:InvokeFunction"
  function_name = each.value.arn
  principal     = "lex.amazonaws.com"
  source_arn    = local.lex_bot_alias_source_arn
}