terraform {
  required_providers {
    sysdig = {
      source  = "sysdiglabs/sysdig"
      version = ">=0.5.33"
    }
  }
}

provider "sysdig" {
  sysdig_secure_api_token = var.sysdig_secure_api_token
  sysdig_secure_url       = var.sysdig_secure_url
}

provider "aws" {
  region = var.region
}

module "cloudvision_aws_single_account_ecs" {
  source           = "../../../examples/single-account-ecs"
  name             = "${var.name}-single"
  role_name        = "test-role-single-ecs"
  trusted_identity = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id      = "b26e5d571ba8f8646e06ff8a8963a84b"
}

output "role_arn" {
  value       = module.cloudvision_aws_single_account_ecs.role_arn
  description = "ARN of cspm role"
}

output "cloudtrail_sns_topic_arn" {
  value       = module.cloudvision_aws_single_account_ecs.cloudtrail_sns_topic_arn
  description = "ARN of cloudtrail sns topic"
}
