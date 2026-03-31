# ============================================================================
# Terraform & Provider Version Requirements
# ============================================================================
# Purpose:
# ----------------------------------------------------------------------------
# - Enforces minimum Terraform version
# - Pins required provider versions to ensure reproducible infrastructure
#
# Notes:
# - Adjust versions as Terraform or AWS provider releases evolve
# - Safe to override locally if developer has higher versions
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20.0" # Ensure compatibility with Lex modules
    }
  }
}