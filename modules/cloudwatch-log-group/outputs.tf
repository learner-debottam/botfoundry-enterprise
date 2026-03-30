# ============================================================================
# Outputs – CloudWatch Log Group Module
# ============================================================================
# Output Summary:
# ----------------------------------------------------------------------------
# | Output Name       | Description                                  |
# |-------------------|----------------------------------------------|
# | log_group_name    | Name of the active CloudWatch Log Group      |
# | log_group_arn     | ARN of the active CloudWatch Log Group       |
#
# Behavior:
# - These outputs are designed to work with conditional resource creation
#   (e.g., when using `count` to create either protected OR unprotected log group).
# - Uses `try()` to safely access resources that may not exist.
# - Uses `coalesce()` to return the first non-null value.
#
# Logic:
# - If `protected` log group exists → return its attributes.
# - Otherwise → fallback to `unprotected` log group.
#
# Notes:
# - This ensures a single consistent output regardless of which resource is created.
# - Prevents Terraform errors when one resource is not instantiated.
# ============================================================================

output "log_group_name" {
  description = "The name of the CloudWatch Log Group"
  value = coalesce(
    try(aws_cloudwatch_log_group.protected[0].name, null),
    try(aws_cloudwatch_log_group.unprotected[0].name, null)
  )
}

output "log_group_arn" {
  description = "The ARN of the CloudWatch Log Group"
  value = coalesce(
    try(aws_cloudwatch_log_group.protected[0].arn, null),
    try(aws_cloudwatch_log_group.unprotected[0].arn, null)
  )
}