# ============================================================================
# Variables – Lambda Module
# ============================================================================
# Variable Summary Table:
# ----------------------------------------------------------------------------
# | Variable Name              | Type / Default                   | Description                                                   |
# |----------------------------|---------------------------------|---------------------------------------------------------------|
# | lambdas                     | map(object)                     | Map of Lambda function configurations (handler, runtime, etc.)|
# | environment_variables       | map(string)                     | Global environment variables applied to all Lambda functions |
# | vpc_subnet_ids              | list(string) / null             | Optional VPC subnet IDs for Lambda functions                 |
# | vpc_security_group_ids      | list(string) / null             | Optional VPC security group IDs for Lambda functions         |
# | tags                        | map(string)                     | Tags applied to all resources                                  |
# | function_tags               | map(string)                     | Tags applied specifically to Lambda functions                |
# | prevent_destroy             | bool / false                    | Enable prevent_destroy for critical environments             |
# | lambda_log_group_arns       | map(string) / {}                | Map of Lambda log group ARNs                                  |
# | lambda_artifacts_bucket     | string                          | S3 bucket containing Lambda deployment artifacts             |
# | lambda_hardening            | bool / true                     | DLQ, code signing, reserved concurrency, KMS for env vars    |
# | reserved_concurrent_executions | number / -1                  | Per-function reserved concurrency when hardening is on       |
# | code_signing_untrusted_behavior | Warn / Enforce             | Code signing policy for unsigned deployment packages         |
#
# Notes:
# - `lambdas` object supports optional fields: `environment_variables`, `source_code_hash`.
# - `vpc_subnet_ids` and `vpc_security_group_ids` allow Lambda to run in private subnets.
# - `prevent_destroy` provides an extra safeguard against accidental deletion.
# - `lambda_artifacts_bucket` must exist and contain all Lambda deployment packages.
# ============================================================================

variable "lambdas" {
  description = "Map of Lambda configurations"
  type = map(object({
    namespace                      = string
    description                    = string
    handler                        = string
    runtime                        = string
    timeout                        = number
    memory_size                    = number
    kms_key_arn                    = string
    s3_key                         = string
    s3_bucket                      = string
    reserved_concurrent_executions = number
    source_code_hash               = optional(string)
    environment_variables          = optional(map(string), {})
  }))
}

variable "environment_variables" {
  description = "Global environment variables applied to all Lambdas"
  type        = map(string)
  default     = {}
}

variable "vpc_subnet_ids" {
  type    = list(string)
  default = null
}

variable "vpc_security_group_ids" {
  type    = list(string)
  default = null
}

variable "tags" {
  type    = map(string)
  default = {}
}

variable "function_tags" {
  type    = map(string)
  default = {}
}

variable "prevent_destroy" {
  description = "Enable prevent_destroy for critical environments"
  type        = bool
  default     = false
}

variable "lambda_log_group_arns" {
  description = "Map of Lambda log group ARNs"
  type        = map(string)
  default     = {}
}

variable "lambda_artifacts_bucket" {
  description = "S3 bucket where Lambda artifacts are stored"
  type        = string
}

# variable "lambda_hardening" {
#   description = "When true, attach DLQ, code signing (untrusted deployments = Warn), reserved concurrency, and KMS for env vars — satisfies common Checkov Lambda rules (CKV_AWS_115/116/173/272)."
#   type        = bool
#   default     = true
# }

variable "reserved_concurrent_executions" {
  description = "Per-function reserved concurrency (-1 = no dedicated cap / use shared pool per AWS provider docs)."
  type        = number
  default     = -1
}

# variable "code_signing_untrusted_behavior" {
#   description = "Lambda code signing policy for unsigned or untrusted artifacts: Warn (allows deploy) or Enforce."
#   type        = string
#   default     = "Warn"

#   validation {
#     condition     = contains(["Warn", "Enforce"], var.code_signing_untrusted_behavior)
#     error_message = "Must be Warn or Enforce."
#   }
# }