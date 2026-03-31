# ============================================================================
# Input Variables – Lex Bot Infrastructure
# ============================================================================
# Purpose:
# ----------------------------------------------------------------------------
# - Defines all configurable inputs for Terraform deployment
#
# Variable Categories:
# ----------------------------------------------------------------------------
# | Category        | Variables                                         |
# |-----------------|-------------------------------------------------- |
# | Environment     | environment                                       |
# | AWS Config      | aws_region, aws_account_id, aws_account_name      |
#
# Notes:
# ----------------------------------------------------------------------------
# - Values are supplied via environment-specific tfvars files
# - Avoid modifying defaults unless necessary
# - These variables are shared across all environments
# ============================================================================
variable "environment" {
  description = "Deployment environment for the resources (e.g., dev, staging, prod). Helps distinguish between different stages of your infrastructure."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "The AWS region where all resources will be created (for example, eu-west-2 for London). Ensure this matches the region of dependent services."
  type        = string
}

variable "aws_account_id" {
  description = "The unique 12-digit identifier of your AWS account where the resources will be deployed."
  type        = string
}

variable "aws_account_name" {
  description = "A readable name for your AWS account (e.g., 'dev-account' or 'production-account'), mainly used for tagging and easier identification."
  type        = string
}