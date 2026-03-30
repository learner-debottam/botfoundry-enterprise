locals {
  bot_config = jsondecode(file("${path.module}/../bot-config.json"))
  bot_name   = local.bot_config.name
  polly_arn  = "arn:aws:polly:${var.aws_region}:${var.aws_account_id}:lexicon/*"

  tags = {
    MANAGED_BY       = "Terraform"
    ENVIRONMENT      = var.environment
    AWS_REGION       = var.aws_region
    AWS_ACCOUNT_NAME = var.aws_account_name
    AWS_ACCOUNT_ID   = var.aws_account_id
  }
}