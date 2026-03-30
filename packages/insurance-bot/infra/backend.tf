terraform {
  backend "s3" {
    bucket         = "my-terraform-state-bucket"
    key            = "insurance-bot/terraform.tfstate" # per package
    region         = "eu-west-2"
    dynamodb_table = "terraform-state-lock"
    encrypt        = true
  }
}