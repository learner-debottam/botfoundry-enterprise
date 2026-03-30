# ============================================================================
# AWS Lex V2 Bot, Locales, Intents, and Slots
# ============================================================================
# Resource Summary Table:
# ----------------------------------------------------------------------------
# | Resource Type                  | Name / Identifier                  | Purpose & Notes                                         |
# |--------------------------------|-----------------------------------|---------------------------------------------------------|
# | aws_lexv2models_bot            | this                              | Core Lex V2 bot definition                              |
# | aws_lexv2models_bot_locale     | locales                            | Defines bot locales and voice settings                 |
# | aws_lexv2models_bot_version    | this                               | Creates stable bot version from DRAFT                  |
# | aws_lexv2models_intent         | intents                            | Defines intents per locale, including prompts, hooks  |
# | aws_lexv2models_slot_type      | slot_types                         | Defines slot types with normalized values & synonyms   |
# | aws_lexv2models_slot           | slots                              | Defines slots per intent and locale                    |
#
# Notes:
# - Bot versioning: All resources are initially created in "DRAFT" mode.
# - Dynamic blocks handle optional features: voice settings, code hooks, prompts, variations.
# - Lifecycle settings prevent accidental destruction and manage update dependencies.
# - Lex IDs are sanitized to meet AWS naming constraints.
# - Fulfillment Lambda functions are linked via local.lambda_map and optional dynamic blocks.
# - Slots respect required/optional constraints, elicit values, and support audio/DTMF/text input.
# ============================================================================

# ============================================================================
# Lex V2 Bot Definition
# ============================================================================
# Core bot resource. Configures name, description, IAM role, type, session TTL, and data privacy.
resource "aws_lexv2models_bot" "this" {
  name        = local.bot_name
  description = lookup(var.bot_config, "description", "Lex bot managed by Terraform")
  role_arn    = aws_iam_role.lex_role.arn
  type        = lookup(var.bot_config, "type", "Bot")

  data_privacy {
    child_directed = lookup(var.bot_config, "child_directed", true)
  }

  idle_session_ttl_in_seconds = lookup(var.bot_config, "idle_session_ttl", 300)
  tags                        = var.tags
}

# ============================================================================
# Lex V2 Bot Locales
# ============================================================================
# Configures locales for the bot, including confidence thresholds and optional voice settings.
resource "aws_lexv2models_bot_locale" "locales" {
  for_each = local.locales

  bot_id                           = aws_lexv2models_bot.this.id
  bot_version                      = "DRAFT"
  locale_id                        = each.key
  description                      = lookup(each.value, "description", "Locale for ${each.key}")
  n_lu_intent_confidence_threshold = each.value.confidence_threshold

  dynamic "voice_settings" {
    for_each = lookup(each.value, "voice_settings", null) == null ? [] : [each.value.voice_settings]
    content {
      voice_id = voice_settings.value.voice_id
      engine   = lookup(voice_settings.value, "engine", null)
    }
  }
}

# ============================================================================
# Lex V2 Bot Version
# ============================================================================
# Creates a stable bot version from the DRAFT version.
# Ensures all locales are included and resources are updated safely.
resource "aws_lexv2models_bot_version" "this" {
  bot_id      = aws_lexv2models_bot.this.id
  description = "Stable version"

  locale_specification = {
    for locale_id, _ in local.locales : locale_id => {
      source_bot_version = "DRAFT"
    }
  }

  lifecycle {
    create_before_destroy = true
  }

  depends_on = [
    aws_lexv2models_intent.intents,
    aws_lexv2models_slot.slots
  ]
}

# ============================================================================
# Lex V2 Intents
# ============================================================================
# Defines intents for each locale, including:
# - Fulfillment code hooks
# - Sample utterances
# - Confirmation, declination, failure, and closing prompts
resource "aws_lexv2models_intent" "intents" {
  for_each = {
    for intent in local.intents :
    "${intent.locale}-${intent.name}" => intent
  }

  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = each.value.locale
  name        = each.value.lex_id
  description = each.value.description

  # dynamic "fulfillment_code_hook" {
  #   for_each = each.value.fulfillment_lambda_name != null ? [1] : []
  #   content { enabled = true }
  # }
  dynamic "fulfillment_code_hook" {
    for_each = each.value.fulfillment_lambda_name != null && length(var.lambda_arns) > 0 ? [1] : []
    content { enabled = true }
  }

  dynamic "sample_utterance" {
    for_each = each.value.sample_utterances
    content { utterance = sample_utterance.value }
  }

  dynamic "initial_response_setting" {
    for_each = each.value.fulfillment_lambda_name != null && length(var.lambda_arns) > 0 ? [1] : []

    content {
      code_hook {
        active                      = true
        enable_code_hook_invocation = true
      }
    }
  }

  dynamic "confirmation_setting" {
    for_each = each.value.confirmation_prompt != null ? [each.value.confirmation_prompt] : []
    content {
      active = true
      prompt_specification {
        message_selection_strategy = each.value.confirmation_prompt.message_selection_strategy != null ? each.value.confirmation_prompt.message_selection_strategy : "Ordered"
        max_retries                = each.value.confirmation_prompt.max_retries != null ? each.value.confirmation_prompt.max_retries : 1

        message_group {
          message {
            plain_text_message {
              value = each.value.confirmation_prompt.message
            }
          }

          dynamic "variation" {
            for_each = lookup(each.value.confirmation_prompt, "variations", [])
            content {
              plain_text_message {
                value = variation.value
              }
            }
          }
        }
      }

      dynamic "confirmation_response" {
        for_each = each.value.confirmation_response != null ? [each.value.confirmation_response] : []
        content {
          message_group {
            message {
              plain_text_message {
                value = confirmation_response.value.message
              }
            }
            dynamic "variation" {
              for_each = lookup(confirmation_response.value, "variations", [])
              content {
                plain_text_message {
                  value = variation.value
                }
              }
            }
          }
        }
      }

      dynamic "declination_response" {
        for_each = each.value.declination_response != null ? [each.value.declination_response] : []
        content {
          message_group {
            message {
              plain_text_message {
                value = declination_response.value.message
              }
            }
            dynamic "variation" {
              for_each = lookup(declination_response.value, "variations", [])
              content {
                plain_text_message {
                  value = variation.value
                }
              }
            }
          }
        }
      }

      dynamic "failure_response" {
        for_each = each.value.failure_response != null ? [each.value.failure_response] : []
        content {
          message_group {
            message {
              plain_text_message {
                value = failure_response.value.message
              }
            }
            dynamic "variation" {
              for_each = lookup(failure_response.value, "variations", [])
              content {
                plain_text_message {
                  value = variation.value
                }
              }
            }
          }
        }
      }
    }
  }

  dynamic "closing_setting" {
    for_each = each.value.closing_prompt != null ? [1] : []
    content {
      active = true
      closing_response {
        message_group {
          message {
            plain_text_message {
              value = each.value.closing_prompt.message
            }
          }
          dynamic "variation" {
            for_each = each.value.closing_prompt.variations
            content {
              plain_text_message {
                value = variation.value
              }
            }
          }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      closing_setting[0].closing_response[0].allow_interrupt
    ]
  }

  depends_on = [
    aws_lexv2models_bot_locale.locales
  ]
}

# ============================================================================
# Lex V2 Slot Types
# ============================================================================
# Defines all slot types per locale, including normalized values and synonyms.
resource "aws_lexv2models_slot_type" "slot_types" {
  for_each = {
    for st in local.slot_types :
    "${st.locale}-${st.name}" => st
  }

  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = each.value.locale
  name        = each.value.lex_id
  description = each.value.description

  dynamic "slot_type_values" {
    for_each = each.value.values
    content {
      sample_value { value = slot_type_values.value.value }

      dynamic "synonyms" {
        for_each = lookup(slot_type_values.value, "synonyms", [])
        content { value = synonyms.value }
      }
    }
  }

  value_selection_setting {
    resolution_strategy = (
      each.value.value_selection_strategy == "RestrictToSlotValues"
      ? "TopResolution"
      : "OriginalValue"
    )
  }

  depends_on = [
    aws_lexv2models_bot_locale.locales
  ]
}

# ============================================================================
# Lex V2 Slots
# ============================================================================
# Defines slots for each intent and locale.
# - Maps to slot types
# - Configures elicitation, prompts, audio/DTMF/text input
resource "aws_lexv2models_slot" "slots" {
  for_each = {
    for slot in local.slots :
    "${slot.locale}-${slot.intent}-${slot.name}" => slot
  }

  bot_id      = aws_lexv2models_bot.this.id
  bot_version = "DRAFT"
  locale_id   = each.value.locale
  intent_id   = aws_lexv2models_intent.intents["${each.value.locale}-${each.value.intent}"].intent_id
  name        = each.value.name
  description = each.value.description

  slot_type_id = startswith(each.value.slot_type, "AMAZON.") ? each.value.slot_type : aws_lexv2models_slot_type.slot_types["${each.value.locale}-${each.value.slot_type}"].slot_type_id

  value_elicitation_setting {
    slot_constraint = each.value.required ? "Required" : "Optional"

    prompt_specification {
      max_retries                = 2
      allow_interrupt            = true
      message_selection_strategy = "Random"

      message_group {
        message {
          plain_text_message {
            value = each.value.prompt
          }
        }
      }

      dynamic "prompt_attempts_specification" {
        for_each = ["Initial", "Retry1", "Retry2"]
        content {
          map_block_key   = prompt_attempts_specification.value
          allow_interrupt = true

          allowed_input_types {
            allow_audio_input = true
            allow_dtmf_input  = true
          }

          audio_and_dtmf_input_specification {
            start_timeout_ms = 4000

            audio_specification {
              max_length_ms  = 15000
              end_timeout_ms = 640
            }

            dtmf_specification {
              max_length         = 513
              end_timeout_ms     = 5000
              deletion_character = "*"
              end_character      = "#"
            }
          }

          text_input_specification { start_timeout_ms = 30000 }
        }
      }
    }
  }

  lifecycle {
    ignore_changes = [
      value_elicitation_setting[0].prompt_specification[0].prompt_attempts_specification,
      value_elicitation_setting[0].prompt_specification[0].allow_interrupt,
      value_elicitation_setting[0].prompt_specification[0].message_selection_strategy,
    ]
  }

  depends_on = [
    aws_lexv2models_intent.intents,
    aws_lexv2models_slot_type.slot_types,
  ]
}