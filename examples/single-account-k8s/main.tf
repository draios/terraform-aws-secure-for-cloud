module "resource_group" {
  source = "../../modules/infrastructure/resource-group"
  name   = var.name
  tags   = var.tags
}

module "ssm" {
  source                  = "../../modules/infrastructure/ssm"
  name                    = var.name
  sysdig_secure_api_token = data.sysdig_secure_connection.current.secure_api_token
  tags                    = var.tags
}

#
# trust-relationship
#

module "cspm_single" {
  source           = "../../modules/services/trust-relationship"
  tags             = var.tags
  role_name        = var.role_name
  trusted_identity = var.trusted_identity
  external_id      = var.external_id
}
