#-------------------------------------
# general resources
#-------------------------------------
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
  source    = "../../modules/services/trust-relationship"
  tags      = var.tags
  role_name = var.role_name
  trusted_identity = var.trusted_identity
  external_id = var.external_id
}


#-------------------------------------
# cloud-connector
#-------------------------------------
module "cloud_connector" {
  source = "../../modules/services/cloud-connector-apprunner"
  name   = "${var.name}-cloudconnector"

  sysdig_secure_api_token      = data.sysdig_secure_connection.current.secure_api_token
  sysdig_secure_url            = data.sysdig_secure_connection.current.secure_url
  secure_api_token_secret_name = module.ssm.secure_api_token_secret_name
  secure_api_token_secret_arn  = module.ssm.secure_api_token_secret_arn

  cloudconnector_ecr_image_uri = var.cloudconnector_ecr_image_uri

  cloudtrail_sns_arn = local.cloudtrail_sns_arn
  tags               = var.tags
}
