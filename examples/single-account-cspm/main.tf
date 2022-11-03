#-------------------------------------
# general resources
#-------------------------------------
module "ssm" {
  source                  = "../../modules/infrastructure/ssm"
  name                    = "sfc-sameer-1"
  sysdig_secure_api_token = data.sysdig_secure_connection.current.secure_api_token
  tags                    = var.tags
}

#
# cspm
#

module "cspm_single" {
  source    = "../../modules/services/cspm"
  tags      = var.tags
  role_name = var.role_name
}