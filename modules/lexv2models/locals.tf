# ============================================================================
# AWS Lex Bot Locals Configuration
# ============================================================================
# Summary:
# ----------------------------------------------------------------------------
# This block defines local variables for configuring Lex V2 bot resources. 
# It normalizes bot data from `var.bot_config` and prepares:
# - Bot name
# - Locales
# - Slot types
# - Intents
# - Slots
# - Lambda function mappings
#
# Notes:
# - Lex IDs are sanitized to meet AWS length and character restrictions.
# - Slot values and synonyms are normalized using try() to handle missing fields.
# - Optional prompts/responses (confirmation, declination, failure, closing) are conditionally created.
# - Lambda map links intents with fulfillment Lambda ARNs if provided.
# ============================================================================

locals {

  # ==========================================================================
  # Bot Name & Locales
  # ==========================================================================
  # Stores the bot's name and supported locales from configuration.
  bot_name = var.bot_config.name
  locales  = var.bot_config.locales

  # ==========================================================================
  # Slot Types
  # ==========================================================================
  # Flattens and normalizes slot types per locale.
  # - Normalizes values and synonyms
  # - Generates Lex-compliant IDs
  slot_types = flatten([
    for locale, locale_data in local.locales : [
      for slot_type_name, slot_type_data in lookup(locale_data, "slot_types", {}) : {
        locale      = locale
        name        = slot_type_name
        description = lookup(slot_type_data, "description", "")

        # Normalized slot values
        values = [
          for v in slot_type_data.values : {
            value    = try(v.value, tostring(v))
            synonyms = try(v.synonyms, [])
          }
        ]

        value_selection_strategy = lookup(
          slot_type_data,
          "value_selection_strategy",
          "ExpandValues"
        )

        # Lex-compliant slot type ID
        lex_id = substr(
          replace(slot_type_name, "/[^0-9a-zA-Z_]/", ""),
          0,
          100
        )
      }
    ]
  ])

  # ==========================================================================
  # Intents
  # ==========================================================================
  # Flattens and normalizes intents per locale.
  # - Includes descriptions, sample utterances, slots, and fulfillment Lambda
  # - Handles optional prompts and responses (confirmation, declination, failure, closing)
  # - Generates Lex-compliant IDs
  intents = flatten([
    for locale, locale_data in local.locales : [
      for intent_name, intent_data in lookup(locale_data, "intents", {}) : {
        locale                  = locale
        name                    = intent_name
        description             = lookup(intent_data, "description", "")
        sample_utterances       = lookup(intent_data, "sample_utterances", [])
        slots                   = lookup(intent_data, "slots", {})
        fulfillment_lambda_name = lookup(intent_data, "fulfillment_lambda_name", null)

        confirmation_prompt = contains(keys(intent_data), "confirmation_prompt") ? {
          message                    = lookup(intent_data.confirmation_prompt, "message", "")
          variations                 = lookup(intent_data.confirmation_prompt, "variations", [])
          message_selection_strategy = lookup(intent_data.confirmation_prompt, "message_selection_strategy", "Ordered")
          max_retries                = lookup(intent_data.confirmation_prompt, "max_retries", 1)
        } : null

        confirmation_response = contains(keys(intent_data), "confirmation_response") ? {
          message    = lookup(intent_data.confirmation_response, "message", "")
          variations = lookup(intent_data.confirmation_response, "variations", [])
        } : null

        declination_response = contains(keys(intent_data), "declination_response") ? {
          message    = lookup(intent_data.declination_response, "message", "")
          variations = lookup(intent_data.declination_response, "variations", [])
        } : null

        failure_response = contains(keys(intent_data), "failure_response") ? {
          message    = lookup(intent_data.failure_response, "message", "")
          variations = lookup(intent_data.failure_response, "variations", [])
        } : null

        closing_prompt = contains(keys(intent_data), "closing_prompt") ? {
          message      = lookup(intent_data.closing_prompt, "message", "")
          variations   = slice(lookup(intent_data.closing_prompt, "variations", []), 0, 2)
          ssml_message = lookup(intent_data.closing_prompt, "ssml_message", "")
        } : null

        # Lex-compliant intent ID
        lex_id = substr(
          replace(intent_name, "/[^0-9a-zA-Z]/", ""),
          0,
          100
        )
      }
    ]
  ])

  # ==========================================================================
  # Slots
  # ==========================================================================
  # Flattens slots for all intents.
  # - Links slots to their intent and slot type
  # - Generates Lex-compliant slot type IDs
  slots = flatten([
    for intent in local.intents : [
      for slot_name, slot_data in intent.slots : {
        locale        = intent.locale
        intent        = intent.name
        name          = slot_name
        description   = lookup(slot_data, "description", "")
        slot_type     = slot_data.slot_type
        required      = slot_data.required
        prompt        = slot_data.prompt
        lex_intent_id = intent.lex_id

        # Map to sanitized Lex slot type ID
        lex_slot_type_id = lookup(
          {
            for st in local.slot_types :
            "${st.locale}-${st.name}" => st.lex_id
          },
          "${intent.locale}-${slot_data.slot_type}",
          slot_data.slot_type
        )
      }
    ]
  ])

  # ==========================================================================
  # Lambda Map
  # ==========================================================================
  # Maps intents to their fulfillment Lambda ARNs if specified.
  lambda_map = {
    for intent in local.intents :
    "${intent.locale}-${intent.name}" => lookup(var.lambda_arns, intent.fulfillment_lambda_name, null)
    if intent.fulfillment_lambda_name != null
  }
}