# ============================================================================
# Terraform Version and Providers
# ============================================================================
# Purpose:
# ----------------------------------------------------------------------------
# - Ensure minimum Terraform version
# - Lock AWS provider version for stability
# ============================================================================

terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 6.20"
    }
  }
}