variable "environment" {
  description = "Deployment environment for the resources (e.g., dev, staging, prod). This helps separate and manage infrastructure across different stages."
  type        = string
  default     = "dev"
}

variable "aws_region" {
  description = "AWS region where all resources will be created (e.g., eu-west-2 for London). Make sure it matches the region of related services."
  type        = string
}

variable "aws_account_id" {
  description = "The unique 12-digit AWS account ID where the infrastructure will be deployed."
  type        = string
}

variable "aws_account_name" {
  description = "A human-readable name for the AWS account (e.g., 'dev-account', 'prod-account'), typically used for tagging and identification."
  type        = string
}

variable "s3_bucket" {
  description = "Name of the Amazon S3 bucket used to store Lambda deployment packages (artifacts such as zipped code files)."
  type        = string
}