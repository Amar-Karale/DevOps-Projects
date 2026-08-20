terraform {
  required_version = ">= 1.6.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.65.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

# CloudFront and its WAF resources are global, with WAF for CloudFront managed in us-east-1.
provider "aws" {
  alias  = "us_east_1"
  region = "us-east-1"
}
