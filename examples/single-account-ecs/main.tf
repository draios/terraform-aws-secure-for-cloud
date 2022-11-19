#-------------------------------------
# general resources
#-------------------------------------
module "resource_group" {
  source = "../../modules/infrastructure/resource-group"

  name = var.name
  tags = var.tags
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

#
# threat-detection
#

module "cloud_connector" {
  source = "../../modules/services/cloud-connector-ecs"
  name   = "${var.name}-cloudconnector"

  secure_api_token_secret_name = module.ssm.secure_api_token_secret_name
  is_organizational            = false

  existing_cloudtrail_config = {
    cloudtrail_sns_arn = local.cloudtrail_sns_arn
  }


  ecs_cluster_name            = local.ecs_cluster_name
  ecs_vpc_id                  = local.ecs_vpc_id
  ecs_vpc_subnets_private_ids = local.ecs_vpc_subnets_private_ids
  ecs_task_cpu                = var.ecs_task_cpu
  ecs_task_memory             = var.ecs_task_memory

  tags       = var.tags
  depends_on = [local.cloudtrail_sns_arn, module.ssm]
}
