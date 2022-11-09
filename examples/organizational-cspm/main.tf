#-------------------------------------
# resources deployed always in management account
# with default provider
#-------------------------------------
module "cspm_org" {
  source    = "../../modules/services/trust-relationship"
  tags      = var.tags
  role_name = var.role_name
  is_organizational = true
}
