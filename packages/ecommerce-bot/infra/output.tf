# ============================================================================
# ────────────────────────────── LEX BOT AND LOG GROUP ──────────────────────────────
# ============================================================================
# Resource Summary:
# ----------------------------------------------------------------------------
# | Resource Type                | Name               | Purpose                                     |
# |------------------------------|------------------|--------------------------------------------|
# | aws_cloudwatch_log_group     | lex_logs          | Log group for Lex bot                        |
# | lexv2_bot                    | lex_bot           | Main Lex V2 bot                              |
#
# Behavior:
# - Creates a single Lex log group
# - Creates Lex V2 bot based on bot-config.json
# - Supports prevent_destroy for production environments
# ============================================================================

output "lex_bot_id" {
  description = "The ID of the Lex bot"
  value       = module.lex.bot_id
}

output "lex_bot_arn" {
  description = "The ARN of the Lex bot"
  value       = module.lex.arn
}

output "cloudwatch_log_group_arn" {
  description = "The ARN of the Lex CloudWatch log group"
  value       = module.logs.log_group_arn
}