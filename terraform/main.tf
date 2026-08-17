terraform {
  backend "s3" {
    bucket         = "3tier-terraform-state-915370161738"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "3tier-terraform-locks"
    encrypt        = true
  }
}