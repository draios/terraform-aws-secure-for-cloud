terraform {
  required_providers {
    aws = {
      version               = ">= 4.0.0"
      configuration_aliases = [aws.member]
    }
    sysdig = {
      source = "sysdiglabs/sysdig"
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


provider "aws" {
  alias  = "member"
  region = var.region
  assume_role {
    # 'OrganizationAccountAccessRole' is the default role created by AWS for management-account users to be able to admin member accounts.
    # <br/>https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html
    role_arn = "arn:aws:iam::${var.sysdig_secure_for_cloud_member_account_id}:role/OrganizationAccountAccessRole"
  }
}

module "org-ecs" {
  providers = {
    aws.member = aws.member
  }
  source = "../../../examples/organizational-ecs"
  name   = var.name

  sysdig_secure_for_cloud_member_account_id = var.sysdig_secure_for_cloud_member_account_id
  role_name                                 = "sameer"
  trusted_identity                          = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id                               = "b26e5d571ba8f8646e06ff8a8963a84b"
  org_units                                 = ["r-op65"]
}

output "role_arn" {
  value       = module.org-ecs.role_arn
  description = "ARN of cspm role"
}

output "cloudtrail_sns_topic_arn" {
  value       = module.org-ecs.cloudtrail_sns_topic_arn
  description = "ARN of cloudtrail sns topic"
}
