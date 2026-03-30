# ============================================================================
# AWS Lex V2 Bot Module Variables
# ============================================================================
# Variable Summary Table:
# ----------------------------------------------------------------------------
# | Variable Name             | Type               | Description / Notes                                                      |
# |---------------------------|------------------|--------------------------------------------------------------------------|
# | bot_config                | any               | Decoded JSON bot configuration; defines bot, locales, intents, slots, etc|
# | lambda_arns               | map(string)       | Optional map of Lambda ARNs keyed by logical names in bot_config          |
# | polly_arn                 | string            | ARN of Amazon Polly; required for TTS voice responses                    |
# | cloudwatch_log_group_arn  | string            | ARN of CloudWatch Log Group for Lex logging                               |
# | lambda_functions          | map(object)       | Map of Lambda objects for Lex intents with function_name and arn         |
# | lexv2_bot_role_name       | string            | Name of the IAM role for Lex V2 bot                                       |
# | tags                      | map(string)       | Optional tags applied to all resources                                    |
# | create_version            | bool              | Whether to create a stable Lex bot version                                 |
#
# Notes:
# - `lambda_arns` is used to link fulfillment Lambda functions dynamically to intents.
# - `polly_arn` and `cloudwatch_log_group_arn` are optional; fine-grained IAM policies are created if provided.
# - `create_version` can be used to conditionally create `aws_lexv2models_bot_version`.
# - All resources support `tags` for cost allocation, auditing, and governance.
# ============================================================================

variable "bot_config" {
  description = "Decoded JSON bot configuration"
  type        = any
}

# variable "lambda_arns" {
#   description = "Optional map of Lambda ARNs keyed by logical names used in bot_config (e.g., fulfillment_lambda_name)"
#   type        = map(string)
#   default     = {}
# }

variable "polly_arn" {
  description = "ARN of polly"
  type        = string
  default     = null
}

variable "cloudwatch_log_group_arn" {
  description = "ARN of CloudWatch Log Group"
  type        = string
  default     = null
}

# variable "lambda_functions" {
#   type = map(object({
#     function_name = string
#     arn           = string
#   }))
#   description = "Map of Lambda function objects for Lex intents"
# }

variable "lexv2_bot_role_name" {
  description = "Name of the IAM role for Lex V2 bot"
  type        = string
  default     = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "create_version" {
  type    = bool
  default = false
}

variable "lambda_arns" {
  description = "Optional map of Lambda ARNs keyed by logical names used in bot_config"
  type        = map(string)
  default     = {}
}

variable "lambda_functions" {
  description = "Optional map of Lambda function objects for Lex intents"
  type = map(object({
    function_name = string
    arn           = string
  }))
  default = {}
}

variable "lex_bot_alias_id" {
  description = "Lex V2 bot alias ID for aws_lambda_permission.source_arn (AWS creates TSTALIASID as the default test alias for new bots)."
  type        = string
  default     = "TSTALIASID"
}