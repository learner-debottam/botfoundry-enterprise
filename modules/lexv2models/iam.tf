# ============================================================================
# AWS Lex V2 – IAM Role & Permissions Setup
# ============================================================================
# Resource Summary Table:
# ----------------------------------------------------------------------------
# | Resource Type                  | Name / Identifier                    | Purpose & Notes                                    |
# |--------------------------------|-------------------------------------|-----------------------------------------------------|
# | data.aws_iam_policy_document    | lex_trust_relationship             | Trust policy allowing Lex V2 service to assume role |
# | aws_iam_role                    | lex_role                           | Core IAM role for Lex V2 bot                        |
# | data.aws_iam_policy_document    | allow_synthesize_speech            | Defines permissions for Amazon Polly TTS            |
# | aws_iam_policy                  | allow_synthesize_speech            | IAM policy for Polly TTS                            |
# | aws_iam_role_policy_attachment  | allow_synthesize_speech            | Attaches Polly policy to Lex role                   |
# | data.aws_iam_policy_document    | allow_lex_cloudwatch_logging       | CloudWatch logging permissions                      |
# | aws_iam_policy                  | allow_lex_cloudwatch_logging       | IAM policy for CloudWatch logging                   |
# | aws_iam_role_policy_attachment  | allow_lex_cloudwatch_logging       | Attaches CloudWatch policy to Lex role              |
# | data.aws_iam_policy_document    | allow_invoke_lambdas (dynamic)     | Lambda invocation permissions (conditional)         |
# | aws_iam_policy                  | allow_invoke_lambdas (dynamic)     | IAM policy for Lambda invocation                    |
# | aws_iam_role_policy_attachment  | allow_invoke_lambdas (dynamic)     | Attaches Lambda policy to Lex role                  |
#
# Notes:
# - Lambda permissions are created only if var.lambda_arns contains ARNs.
# - All resources are taggable via var.tags.
# - Fine-grained permissions are used instead of broad managed policies.
# ============================================================================

# ============================================================================
# Trust Relationship: Lex V2 → IAM Role
# ============================================================================
# Allows the Lex V2 service (lexv2.amazonaws.com) to assume this IAM role.
# Mandatory for any Lex bot to function.
data "aws_iam_policy_document" "lex_trust_relationship" {
  statement {
    effect = "Allow"
    principals {
      type        = "Service"
      identifiers = ["lexv2.amazonaws.com"]
    }
    actions = ["sts:AssumeRole"]
  }
}

# ============================================================================
# IAM Role for Lex V2 Bot
# ============================================================================
# Defines the core IAM role that Lex V2 will assume.
# Supports tags and extended session duration.
resource "aws_iam_role" "lex_role" {
  name                 = var.lexv2_bot_role_name
  assume_role_policy   = data.aws_iam_policy_document.lex_trust_relationship.json
  tags                 = var.tags
  max_session_duration = 43200
}

# ============================================================================
# Polly Permissions (Text-to-Speech)
# ============================================================================
# Grants Lex permission to synthesize speech using Amazon Polly.
# Required if the bot is configured with voice responses.
data "aws_iam_policy_document" "allow_synthesize_speech" {
  statement {
    sid    = "LexActions"
    effect = "Allow"
    actions = [
      "polly:SynthesizeSpeech"
    ]
    resources = [
      var.polly_arn
    ]
  }
}

resource "aws_iam_policy" "allow_synthesize_speech" {
  name   = "${local.bot_name}-allow-synthesize-speech-policy"
  policy = data.aws_iam_policy_document.allow_synthesize_speech.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "allow_synthesize_speech" {
  role       = aws_iam_role.lex_role.name
  policy_arn = aws_iam_policy.allow_synthesize_speech.arn
}

# ============================================================================
# CloudWatch Logging Permissions
# ============================================================================
# Enables Lex to create log groups, create log streams, and push logs to
# CloudWatch. Essential for debugging, monitoring, and production observability.
data "aws_iam_policy_document" "allow_lex_cloudwatch_logging" {
  statement {
    sid    = "AllowLexCloudWatchLogging"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:CreateLogGroup"
    ]
    resources = [
      var.cloudwatch_log_group_arn
    ]
  }
}

resource "aws_iam_policy" "allow_lex_cloudwatch_logging" {
  name   = "${local.bot_name}-allow-lex-cloudwatch-logging-policy"
  policy = data.aws_iam_policy_document.allow_lex_cloudwatch_logging.json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "allow_lex_cloudwatch_logging" {
  role       = aws_iam_role.lex_role.name
  policy_arn = aws_iam_policy.allow_lex_cloudwatch_logging.arn
}

# ============================================================================
# Lambda Invocation Permissions (Dynamic)
# ============================================================================
# Grants Lex permission to invoke Lambda functions for fulfillment or validation.
# Created only if Lambda ARNs are provided to avoid unnecessary permissions.
# data "aws_iam_policy_document" "allow_invoke_lambdas" {
#   count = length(var.lambda_arns) > 0 ? 1 : 0

#   statement {
#     sid    = "AllowInvokeLambdas"
#     effect = "Allow"
#     actions = [
#       "lambda:InvokeFunction",
#       "lambda:InvokeAsync"
#     ]
#     resources = values(var.lambda_arns)
#   }
# }

# resource "aws_iam_policy" "allow_invoke_lambdas" {
#   count  = length(var.lambda_arns) > 0 ? 1 : 0
#   name   = "${local.bot_name}-allow-invoke-lambdas-policy"
#   policy = data.aws_iam_policy_document.allow_invoke_lambdas[0].json
#   tags   = var.tags
# }

# resource "aws_iam_role_policy_attachment" "allow_invoke_lambdas" {
#   count      = length(var.lambda_arns) > 0 ? 1 : 0
#   role       = aws_iam_role.lex_role.name
#   policy_arn = aws_iam_policy.allow_invoke_lambdas[0].arn
# }

data "aws_iam_policy_document" "allow_invoke_lambdas" {
  count = length(var.lambda_arns) > 0 ? 1 : 0

  statement {
    sid    = "AllowInvokeLambdas"
    effect = "Allow"
    actions = [
      "lambda:InvokeFunction",
      "lambda:InvokeAsync"
    ]
    resources = values(var.lambda_arns)
  }
}

resource "aws_iam_policy" "allow_invoke_lambdas" {
  count  = length(var.lambda_arns) > 0 ? 1 : 0
  name   = "${local.bot_name}-allow-invoke-lambdas-policy"
  policy = data.aws_iam_policy_document.allow_invoke_lambdas[0].json
  tags   = var.tags
}

resource "aws_iam_role_policy_attachment" "allow_invoke_lambdas" {
  count      = length(var.lambda_arns) > 0 ? 1 : 0
  role       = aws_iam_role.lex_role.name
  policy_arn = aws_iam_policy.allow_invoke_lambdas[0].arn
}