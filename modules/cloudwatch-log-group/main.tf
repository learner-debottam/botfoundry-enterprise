# ============================================================================
# CloudWatch Log Group – Conditional Protection
# ============================================================================
# Resource Summary:
# ----------------------------------------------------------------------------
# | Resource Type                | Name         | Purpose                                  |
# |------------------------------|--------------|------------------------------------------|
# | aws_cloudwatch_log_group     | protected    | Log group with prevent_destroy enabled   |
# | aws_cloudwatch_log_group     | unprotected  | Standard log group without protection    |
#
# Behavior:
# - This module conditionally creates one of two log groups based on `var.prevent_destroy`.
# - If `prevent_destroy = true`:
#     → Creates `protected` log group with lifecycle protection.
# - If `prevent_destroy = false`:
#     → Creates `unprotected` log group without lifecycle protection.
#
# Key Features:
# - Supports configurable log retention (`retention_in_days`).
# - Optional KMS encryption via `kms_key_id`.
# - Tagging support for resource organization.
#
# Notes:
# - Only ONE log group is created at a time (mutually exclusive via `count`).
# - `prevent_destroy` is useful for production environments to avoid accidental deletion.
# - When switching `prevent_destroy`, Terraform will replace the resource.
# ============================================================================

resource "aws_cloudwatch_log_group" "protected" {
  count             = var.prevent_destroy ? 1 : 0
  name              = var.name
  retention_in_days = var.retention_in_days != null ? var.retention_in_days : 365
  kms_key_id        = var.kms_key_id != null ? var.kms_key_id : null
  tags              = var.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "aws_cloudwatch_log_group" "unprotected" {
  count             = var.prevent_destroy ? 0 : 1
  name              = var.name
  retention_in_days = var.retention_in_days != null ? var.retention_in_days : 365
  kms_key_id        = var.kms_key_id != null ? var.kms_key_id : null
  tags              = var.tags
}