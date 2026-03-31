# ============================================================================
# Local Values for Lex Bot with Lambda
# ============================================================================
# Purpose:
# ----------------------------------------------------------------------------
# - Read bot configuration
# - Build Lambda resource map dynamically
# - Define tags and common ARNs for resources
# ============================================================================

locals {
  # Load bot configuration
  bot_config = try(
    jsondecode(file("${path.module}/../bot-config.json")),
    {}
  )
  # Extract bot name from config
  bot_name = local.bot_config.name

  # Polly ARN (used for Lex voice capabilities if needed)
  polly_arn = "arn:aws:polly:${var.aws_region}:${var.aws_account_id}:lexicon/*"
  # Namespace of the Lex 
  namespace = "${var.aws_account_name}-${var.environment}-${local.bot_name}"
  # Flatten intents per locale
  intents = flatten([
    for locale, locale_data in local.bot_config.locales : [
      for intent_name, intent in locale_data.intents : merge(intent, {
        intent_name = intent_name
        locale      = locale
      })
    ]
  ])

  # Only intents that have Lambda fulfillment
  lambda_intents = [
    for intent in local.intents : intent
    if lookup(intent, "fulfillment_lambda_name", null) != null
  ]

  # Map Lambda definitions dynamically
  lambdas = {
    for intent in local.lambda_intents : intent.fulfillment_lambda_name => {
      namespace                      = local.namespace
      description                    = intent.description
      handler                        = "index.handler"
      runtime                        = "nodejs24.x"
      timeout                        = floor(lookup(intent.lambda_config, "timeout_ms", 3000) / 1000)
      memory_size                    = 1024
      kms_key_arn                    = null
      s3_key                         = "${intent.fulfillment_lambda_name}.zip"
      s3_bucket                      = var.s3_bucket
      reserved_concurrent_executions = -1
      environment_variables = {
        INTENT_NAME = intent.fulfillment_lambda_name
      }
    }
  }

  tags = {
    MANAGED_BY       = "BotFoundry"
    ENVIRONMENT      = var.environment
    AWS_REGION       = var.aws_region
    AWS_ACCOUNT_NAME = var.aws_account_name
    AWS_ACCOUNT_ID   = var.aws_account_id
  }
}