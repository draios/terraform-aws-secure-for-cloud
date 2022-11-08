#
# trust-relationship
#

module "cspm_single" {
  source    = "../../modules/services/trust-relationship"
  tags      = var.tags
  role_name = var.role_name
}