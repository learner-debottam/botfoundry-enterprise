# ============================================================================
# AWS Lex V2 Bot Outputs
# ============================================================================
# Resource Summary Table:
# ----------------------------------------------------------------------------
# | Output Name           | Description                                                   |
# |-----------------------|---------------------------------------------------------------|
# | bot_id                | The unique ID of the Lex V2 bot                               |
# | bot_name              | The name of the Lex V2 bot                                     |
# | bot_version           | The stable bot version (Lex V2)                               |
# | locales               | List of locale IDs configured on the bot (e.g., en_US, en_GB) |
# | intents               | Map of intents with intent_id, name, and locale_id            |
# | slots                 | Map of slots with slot_id, name, intent_id, and locale_id     |
# | intents_config        | Original intents structure from locals                        |
#
# Notes:
# - `intents_config` preserves the original flattened intent configuration
#   with all prompts, responses, slots, and fulfillment Lambda mapping.
# - These outputs allow external modules or scripts to reference bot structure
#   and IDs for integration, automation, or testing.
# ============================================================================

output "bot_id" {
  value = aws_lexv2models_bot.this.id
}

output "bot_name" {
  value = aws_lexv2models_bot.this.name
}

output "bot_version" {
  value = aws_lexv2models_bot_version.this.bot_version
}

output "locales" {
  description = "Locales configured on the bot (keys are locale IDs such as en_US, en_GB)"
  value       = keys(local.locales)
}

output "intents" {
  value = {
    for k, v in aws_lexv2models_intent.intents :
    k => {
      intent_id = v.intent_id
      name      = v.name
      locale    = v.locale_id
    }
  }
}

output "slots" {
  value = {
    for k, v in aws_lexv2models_slot.slots :
    k => {
      slot_id   = v.slot_id
      name      = v.name
      intent_id = v.intent_id
      locale    = v.locale_id
    }
  }
}

# VERY IMPORTANT → pass original structure for full reference
output "intents_config" {
  value = local.intents
}