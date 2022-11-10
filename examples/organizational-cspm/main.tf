#-------------------------------------
# resources deployed always in management account
# with default provider
#-------------------------------------
#-------------------------------------
# resources deployed always in management account
# with default provider
#-------------------------------------
module "cspm_org" {
  providers = {
    aws = aws.member
  }
  source    = "../../modules/services/trust-relationship"
  tags      = var.tags
  role_name = var.role_name
  trusted_identity = var.trusted_identity
  external_id = var.external_id
  is_organizational = true
}
