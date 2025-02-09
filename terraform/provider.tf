terraform {
  backend "s3" {
    bucket  = "labos-terraform-state-bucket-01"
    key     = "state/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
    profile = "labos"
  }

  required_version = ">= 0.12"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}

# Configure the AWS provider and specify the "labos" profile
provider "aws" {
  region  = var.aws_region
  profile = "labos"
}
