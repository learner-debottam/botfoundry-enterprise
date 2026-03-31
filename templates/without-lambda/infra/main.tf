# ============================================================================
# Main Terraform Configuration – Lex Bot Platform
# ============================================================================
# Purpose:
# ----------------------------------------------------------------------------
# - Defines the core resources and modules for a Lex bot without Lambda
# - Integrates CloudWatch log group and Lex V2 bot module
# - Uses bot-config.json for configuration
#
# Modules Summary:
# ----------------------------------------------------------------------------
# | Module | Source                          | Purpose                                    |
# |--------|---------------------------------|--------------------------------------------|
# | logs   | modules/cloudwatch-log-group    | Creates CloudWatch log group for Lex bot   |
# | lex    | modules/lexv2models             | Creates Lex V2 bot using bot_config.json   |
#
# Notes:
# - `local.bot_name` is derived from bot-config.json
# - Template placeholders: {{BOT_NAME}} will be replaced by generator
# - Prevent destroy is applied for prod environment
# ============================================================================

# CloudWatch Logs Module
module "logs" {
  source = "../../../modules/cloudwatch-log-group"

  name              = "/aws/lex/${local.bot_name}" # Logs namespaced by bot name
  retention_in_days = 365                          # Keep logs for 1 year
  prevent_destroy   = var.environment == "prod"    # Protect prod logs
}

# Lex V2 Bot Module
module "lex" {
  source = "../../../modules/lexv2models"

  bot_config = local.bot_config # Configuration from JSON

  cloudwatch_log_group_arn = module.logs.log_group_arn # Attach logs

  polly_arn = local.polly_arn # Polly lexicon access

  lexv2_bot_role_name = "${var.aws_account_name}-${var.environment}-${local.bot_name}-lex-iam-role"
}