#
# cspm
#

module "cspm_single" {
  source    = "../../modules/services/cspm"
  tags      = var.tags
  role_name = var.role_name
}