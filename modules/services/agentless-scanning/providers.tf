provider "aws" {
  region = "us-east-1"

  default_tags {
    tags = {
      "sysdig:secure:initiative" = "Sysdig Secure Agentless"
    }
  }
}

# terraform {
#   # The configuration for this backend will be filled in by Terragrunt
#   backend "s3" {}

#   # Minimum version of terraform required for this module
#   required_version = ">= 0.13"

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "~> 4.59.0"
#     }
#   }
# }
