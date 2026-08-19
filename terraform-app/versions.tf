terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.4"
    }
  }

  # Points at the bucket/table created by the bootstrap config. This app
  # directory has its own, separate state from bootstrap — see earlier
  # discussion on why they're kept apart (circular deps, blast radius,
  # privilege separation).
  backend "s3" {
    bucket         = "3tier-terraform-state-915370161738"
    key            = "app/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "3tier-terraform-locks"
    encrypt        = true
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_caller_identity" "current" {}
