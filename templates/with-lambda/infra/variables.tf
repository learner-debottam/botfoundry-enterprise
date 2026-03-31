# ============================================================================
# Terraform Variables for Lex Bot with Lambda
# ============================================================================
# Purpose:
# ----------------------------------------------------------------------------
# - Define all environment, AWS, and Lambda-specific variables
# - Keep infrastructure configurable for multiple environments
# - Avoid hardcoding sensitive values
# ============================================================================

variable "environment" {
  description = "Deployment environment for the resources (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region where all resources will be created (e.g., eu-west-2)."
  type        = string
}

variable "aws_account_id" {
  description = "The unique 12-digit AWS account ID where the infrastructure will be deployed."
  type        = string
}

variable "aws_account_name" {
  description = "A human-readable name for the AWS account (e.g., 'dev-account', 'prod-account'), typically used for tagging."
  type        = string
}

variable "s3_bucket" {
  description = "Name of the Amazon S3 bucket used to store Lambda deployment packages."
  type        = string
}