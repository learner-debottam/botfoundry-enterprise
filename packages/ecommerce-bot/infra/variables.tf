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
  description = "Deployment environment for the resources (e.g., dev, staging, prod)."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region where all resources will be created (e.g., eu-west-2)."
  type        = string
}

variable "aws_account_id" {
  description = "The 12-digit AWS account ID where the infrastructure will be deployed."
  type        = string
}

variable "aws_account_name" {
  description = "Human-readable AWS account name (e.g., dev, prod) used for tagging."
  type        = string
}