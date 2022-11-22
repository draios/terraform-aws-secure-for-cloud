provider "aws" {
  region = "us-east-1"
}

module "org_cspm" {
  source           = "../../../modules/services/trust-relationship"
  trusted_identity = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id      = "b26e5d571ba8f8646e06ff8a8963a84b"
  role_name        = "sameer-org"
  org_units        = ["r-op65"]
  is_organizational = true
}

output "role_arn" {
  value       = module.org_cspm.cspm_role_arn
  description = "ARN of cspm role"
}
