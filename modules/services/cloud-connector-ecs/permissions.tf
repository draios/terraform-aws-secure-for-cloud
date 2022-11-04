locals {
  ecs_task_role_id          = var.is_organizational ? data.aws_iam_role.task_inherited[0].id : aws_iam_role.task[0].id
  ecs_task_role_arn         = var.is_organizational ? data.aws_iam_role.task_inherited[0].arn : aws_iam_role.task[0].arn
  ecs_task_role_name_suffix = var.is_organizational ? var.organizational_config.connector_ecs_task_role_name : var.connector_ecs_task_role_name
}

data "aws_ssm_parameter" "sysdig_secure_api_token" {
  name = var.secure_api_token_secret_name
}

#---------------------------------
# task role
# - if organizational, role is inherited from root lvl, to avoid cyclic dependencies
# - otherwise is created in current account
# - duplicated in /examples/organizational/permissions.tf
#---------------------------------
data "aws_iam_role" "task_inherited" {
  count = var.is_organizational ? 1 : 0
  name  = var.organizational_config.connector_ecs_task_role_name
}

resource "aws_iam_role" "task" {
  count              = var.is_organizational ? 0 : 1
  name               = "${var.name}-${local.ecs_task_role_name_suffix}"
  assume_role_policy = data.aws_iam_policy_document.task_assume_role[0].json
  path               = "/"
  tags               = var.tags
}

data "aws_iam_policy_document" "task_assume_role" {
  count = var.is_organizational ? 0 : 1
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}

resource "aws_iam_role_policy" "task_policy_sqs" {
  name   = "${var.name}-AllowSQSUsage"
  role   = local.ecs_task_role_id
  policy = data.aws_iam_policy_document.iam_role_task_policy_sqs.json
}
data "aws_iam_policy_document" "iam_role_task_policy_sqs" {
  statement {
    effect = "Allow"
    actions = [
      "sqs:DeleteMessage",
      "sqs:ReceiveMessage"
    ]
    resources = [
      local.deploy_sqs ? module.cloud_connector_sqs[0].cloudtrail_sns_subscribed_sqs_arn : var.existing_cloudtrail_config.cloudtrail_s3_sns_sqs_arn
    ]
  }
}

resource "aws_iam_role_policy" "task_policy_s3" {
  count  = var.is_organizational ? 0 : 1
  name   = "${var.name}-AllowS3Read"
  role   = local.ecs_task_role_id
  policy = data.aws_iam_policy_document.iam_role_task_policy_s3[0].json
}
data "aws_iam_policy_document" "iam_role_task_policy_s3" {
  count = var.is_organizational ? 0 : 1
  statement {
    effect = "Allow"
    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]
    resources = ["*"]
    # resources = [var.cloudtrail_s3_arn # would need this as param]
  }
}

resource "aws_iam_role_policy" "task_policy_assume_role" {
  count  = var.is_organizational ? 1 : 0
  name   = "${var.name}-AllowS3AssumeRole"
  role   = local.ecs_task_role_id
  policy = data.aws_iam_policy_document.iam_role_task_assume_role[0].json
}

data "aws_iam_policy_document" "iam_role_task_assume_role" {
  count = var.is_organizational ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "sts:AssumeRole"
    ]
    resources = [var.organizational_config.sysdig_secure_for_cloud_role_arn]
  }
}

#
# scan images
#

#---------------------------------
# execution role
# This role is required by tasks to pull container images and publish container logs to Amazon CloudWatch on your behalf.
#---------------------------------
resource "aws_iam_role" "execution" {
  name               = "${var.name}-ECSTaskExecutionRole"
  assume_role_policy = data.aws_iam_policy_document.execution_assume_role.json
  path               = "/"
  tags               = var.tags
}
data "aws_iam_policy_document" "execution_assume_role" {
  statement {
    effect = "Allow"
    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]
      type        = "Service"
    }
    actions = ["sts:AssumeRole"]
  }
}


resource "aws_iam_role_policy" "task_read_parameters" {
  name   = "${var.name}-TaskReadParameters"
  policy = data.aws_iam_policy_document.task_read_parameters.json
  role   = aws_iam_role.execution.id
}
data "aws_iam_policy_document" "task_read_parameters" {
  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters"]
    resources = [data.aws_ssm_parameter.sysdig_secure_api_token.arn]
  }
}


resource "aws_iam_role_policy" "execution" {
  name   = "${var.name}-ExecutionRolePolicy"
  policy = data.aws_iam_policy_document.execution.json
  role   = aws_iam_role.execution.id
}
data "aws_iam_policy_document" "execution" {
  statement {
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }
}
