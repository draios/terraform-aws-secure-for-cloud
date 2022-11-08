#-------------------------------------
# resources deployed always in management account
# with default provider
#-------------------------------------
locals {
  deploy_same_account  = data.aws_caller_identity.me.account_id == var.sysdig_secure_for_cloud_member_account_id
}

module "resource_group" {
  source = "../../modules/infrastructure/resource-group"
  name   = var.name
  tags   = var.tags
}

module "resource_group_secure_for_cloud_member" {
  count = local.deploy_same_account ? 0 : 1
  providers = {
    aws = aws.member
  }
  source = "../../modules/infrastructure/resource-group"
  name   = var.name
  tags   = var.tags
}

module "cspm_org" {
  source    = "../../modules/services/trust-relationship"
  tags      = var.tags
  role_name = var.role_name
  is_organizational = true
}
