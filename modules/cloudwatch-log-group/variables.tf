# ============================================================================
# Variables – CloudWatch Log Group Module
# ============================================================================
# Variable Summary Table:
# ----------------------------------------------------------------------------
# | Variable Name        | Type / Default     | Description                                 |
# |----------------------|--------------------|---------------------------------------------|
# | name                 | string             | Name of the CloudWatch Log Group            |
# | retention_in_days    | number / 30        | Number of days to retain logs               |
# | kms_key_id           | string / null      | Optional KMS key ARN for encryption         |
# | tags                 | map(string) / {}   | Tags applied to the log group               |
# | prevent_destroy      | bool / false       | Prevent accidental deletion (prod safety)   |
#
# Notes:
# - `name` must be unique per AWS account/region.
# - `retention_in_days` controls log lifecycle and cost optimization.
# - `kms_key_id` enables encryption at rest for sensitive logs.
# - `prevent_destroy` should be enabled in production environments.
# - `tags` help with cost allocation and resource organization.
# ============================================================================

variable "name" {
  description = "Name of the CloudWatch Log Group"
  type        = string
}

variable "retention_in_days" {
  description = "Number of days to retain logs"
  type        = number
  default     = 365
}

variable "kms_key_id" {
  description = "Optional KMS key ARN for log encryption"
  type        = string
  default     = null
}

variable "tags" {
  description = "Tags to apply to the CloudWatch Log Group"
  type        = map(string)
  default     = {}
}

variable "prevent_destroy" {
  description = "Whether to prevent accidental deletion (e.g., in prod)"
  type        = bool
  default     = false
}