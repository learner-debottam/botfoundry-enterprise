terraform {
  required_version = ">= 1.5.0"
}

module "logs" {
  source = "../../../modules/cloudwatch-log-group"

  name              = "/aws/lex/${local.bot_name}"
  retention_in_days = 365
  prevent_destroy   = var.environment == "prod"
}

module "lex" {
  source = "../../../modules/lexv2models"

  bot_config = local.bot_config

  cloudwatch_log_group_arn = module.logs.log_group_arn

  polly_arn = local.polly_arn

  lexv2_bot_role_name = "${var.aws_account_name}-${var.environment}-${local.bot_name}-lex-iam-role"
}