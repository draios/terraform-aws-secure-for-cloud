#-------------------------------------
# resources deployed always in management account
# with default provider
#-------------------------------------
locals {
  deploy_same_account                      = data.aws_caller_identity.me.account_id == var.sysdig_secure_for_cloud_member_account_id
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

#-------------------------------------
# secure-for-cloud member account workload
#-------------------------------------
module "ssm" {
  providers = {
    aws = aws.member
  }
  source                  = "../../modules/infrastructure/ssm"
  name                    = var.name
  sysdig_secure_api_token = data.sysdig_secure_connection.current.secure_api_token
  tags                    = var.tags
}

module "cspm_org" {
  source            = "../../modules/services/trust-relationship"
  tags              = var.tags
  role_name         = var.role_name
  trusted_identity  = var.trusted_identity
  external_id       = var.external_id
  is_organizational = true
  region            = data.aws_region.current.name
  org_units         = var.org_units
}

module "cloud_connector" {
  providers = {
    aws = aws.member
  }

  source = "../../modules/services/cloud-connector-ecs"
  name   = "${var.name}-cloudconnector"

  secure_api_token_secret_name = module.ssm.secure_api_token_secret_name

  #
  # note;
  # these two variables `is_organizational` and `organizational_config` is for image-scanning requirements (double inception)
  # this must still be true to be able to handle future image-scanning
  # is_organizational means that it will attempt an assumeRole on management account, as cloud_connector is deployed on `aws.member` alias
  #
  # TODO
  # - avoid all these parameters if `deploy_image_scanning_ecr` and `deploy_image_scanning_ecs` == false
  # - is_organizational to be renamed to enable_management_account_assume_role?
  # - we could check whether aws.member = aws (management account) infer the value of the variable
  #
  is_organizational = true
  organizational_config = {
    # see local.deploy_org_management_sysdig_role notes
    sysdig_secure_for_cloud_role_arn = local.deploy_org_management_sysdig_role ? module.secure_for_cloud_role[0].sysdig_secure_for_cloud_role_arn : var.existing_cloudtrail_config.cloudtrail_s3_role_arn
    organizational_role_per_account  = var.organizational_member_default_admin_role
    connector_ecs_task_role_name     = aws_iam_role.connector_ecs_task.name
  }

  existing_cloudtrail_config = {
    cloudtrail_sns_arn        = local.cloudtrail_sns_arn
    cloudtrail_s3_sns_sqs_url = var.existing_cloudtrail_config.cloudtrail_s3_sns_sqs_url
    cloudtrail_s3_sns_sqs_arn = var.existing_cloudtrail_config.cloudtrail_s3_sns_sqs_arn
  }

  ecs_cluster_name            = local.ecs_cluster_name
  ecs_vpc_id                  = local.ecs_vpc_id
  ecs_vpc_subnets_private_ids = local.ecs_vpc_subnets_private_ids
  ecs_task_cpu                = var.ecs_task_cpu
  ecs_task_memory             = var.ecs_task_memory

  tags       = var.tags
  depends_on = [local.cloudtrail_sns_arn, module.ssm]
}
