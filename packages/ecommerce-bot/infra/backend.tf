# ============================================================================
# Terraform Backend Configuration (Managed via CI/CD)
# ============================================================================
# IMPORTANT:
# ----------------------------------------------------------------------------
# - Backend configuration is NOT defined in this template.
# - It is dynamically injected by the CI/CD pipeline during `terraform init`.
#
# Why?
# ----------------------------------------------------------------------------
# - Avoids hardcoding environment-specific values
# - Enables reuse across multiple AWS accounts and environments
# - Keeps infrastructure portable and secure
#
# Pipeline Example:
# ----------------------------------------------------------------------------
# terraform init \
#   -backend-config="bucket=<STATE_BUCKET>" \
#   -backend-config="key=<PACKAGE_NAME>/terraform.tfstate" \
#   -backend-config="region=<AWS_REGION>" \
#   -backend-config="dynamodb_table=<LOCK_TABLE>"
#
# Notes:
# ----------------------------------------------------------------------------
# - Do NOT add backend config here unless running Terraform locally
# - For local testing, you may temporarily define a backend
# ============================================================================

terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "ecommerce-bot/terraform.tfstate" # per package
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}