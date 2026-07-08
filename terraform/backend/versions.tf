terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # Intentionally no backend block here: this configuration creates the
  # S3 bucket and DynamoDB table that every other environment uses as its
  # remote backend, so it must run against local state first.
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project   = var.project_name
      ManagedBy = "terraform"
      Component = "state-backend"
    }
  }
}
