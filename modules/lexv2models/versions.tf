# ============================================================================
# Terraform Configuration
# ============================================================================
# Provider Requirements:
# ----------------------------------------------------------------------------
# | Provider | Source           | Version Constraint          | Notes                                |
# |----------|-----------------|----------------------------|--------------------------------------|
# | aws      | hashicorp/aws    | >= 6.20                    | Required for all AWS resources in this module (Lex, Lambda, IAM, CloudWatch, Polly) |
#
# Notes:
# - Ensures Terraform uses AWS provider version 6.20 or higher.
# - Required for compatibility with aws_lexv2models_* resources and IAM policies.
# - Can be extended with additional providers if needed.
# ============================================================================

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20"
    }
  }
}