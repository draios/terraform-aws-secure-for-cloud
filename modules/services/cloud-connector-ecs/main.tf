data "aws_region" "current" {}

locals {
  verify_ssl = var.verify_ssl == "auto" ? length(regexall("https://.*?\\.sysdig(cloud)?.com/?", data.sysdig_secure_connection.current.secure_url)) == 1 : var.verify_ssl == "true"
  cloudtrail_deploy  = var.cloudtrail_sns_arn == "create"
  cloudtrail_sns_arn = local.cloudtrail_deploy ? module.cloudtrail[0].cloudtrail_sns_arn : var.cloudtrail_sns_arn
  ecs_deploy                  = var.ecs_cluster_name == "create"
  ecs_cluster_name            = local.ecs_deploy ? module.ecs_vpc[0].ecs_cluster_name : var.ecs_cluster_name
  ecs_vpc_id                  = local.ecs_deploy ? module.ecs_vpc[0].ecs_vpc_id : var.ecs_vpc_id
  ecs_vpc_subnets_private_ids = local.ecs_deploy ? module.ecs_vpc[0].ecs_vpc_subnets_private_ids : var.ecs_vpc_subnets_private_ids

}

#-------------------------------------
# general resources
#-------------------------------------
module "resource_group" {
  source = "../../infrastructure/resource-group"

  name = var.name
  tags = var.tags
}

module "ssm" {
  source                  = "../../infrastructure/ssm"
  name                    = var.name
  sysdig_secure_api_token = data.sysdig_secure_connection.current.secure_api_token
  tags                    = var.tags
}

module "cloudtrail" {
  count                     = local.cloudtrail_deploy ? 1 : 0
  source                    = "../../infrastructure/cloudtrail"
  name                      = var.name
  is_organizational         = false
  is_multi_region_trail     = var.cloudtrail_is_multi_region_trail
  cloudtrail_kms_enable     = var.cloudtrail_kms_enable
  s3_bucket_expiration_days = var.cloudtrail_s3_bucket_expiration_days

  tags = var.tags
}

module "ecs_vpc" {
  count = local.ecs_deploy ? 1 : 0

  source             = "../../infrastructure/ecs-vpc"
  name               = var.name

  ecs_vpc_region_azs = var.ecs_vpc_region_azs
  tags               = var.tags
}


