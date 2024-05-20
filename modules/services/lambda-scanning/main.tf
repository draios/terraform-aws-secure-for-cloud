###########################################
# Workload Controller IAM roles and stuff #
###########################################

#-----------------------------------------------------------------------------------------------------------------------
# Determine if this is an Organizational install, or a single account install. For Single Account installs, resources
# are created directly using the AWS Terraform Provider (This is the default behaviour). For Organizational installs,
# see organizational.tf, and the resources in this file are used to instrument the management account (StackSets do not
# include the management account they are created in, even if this account is within the target Organization).
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# We have two types of resources. global and regional. Global resources are deployed only once (mostly in the primary
# region). We use deploy_global_resources boolean to determine that.
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# These resources create an Agentless Workload Scanning IAM Role and IAM Policy in the account.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "scanning" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  # General ECR read permission, necessary for the fetching artifacts.
  # Plus read-only lambda permissions
  statement {
    sid = "EcrReadPermissions"

    effect = "Allow"

    actions = [
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:ListImages",
      "ecr:GetAuthorizationToken",
    ]

    resources = [
      "*",
    ]
  }

  statement {
    sid = "Full ready-only lambda permissions"

    effect = "Allow"

    actions = [
      "lambda:GetFunction",
      "lambda:GetFunctionConfiguration",
      "lambda:GetRuntimeManagementConfig",
      "lambda:ListFunctions",
      "lambda:ListTagsForResource",
      "lambda:GetLayerVersionByArn",
      "lambda:GetLayerVersion",
      "lambda:ListLayers",
      "lambda:ListLayerVersions"
    ]

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "lambda_scanning" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  name        = var.ecr_role_name
  description = "Grants Sysdig Secure access to ECR images and Lambda Functions"
  policy      = data.aws_iam_policy_document.scanning[0].json
  tags        = var.tags
}

data "aws_iam_policy_document" "scanning_assume_role_policy" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  statement {
    sid = "SysdigLambdaScanning"

    actions = [
      "sts:AssumeRole"
    ]

    principals {
      type = "AWS"
      identifiers = [
        var.trusted_identity,
      ]
    }

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "scanning" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  name               = var.ecr_role_name
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.scanning_assume_role_policy[0].json
}

resource "aws_iam_policy_attachment" "scanning" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  name       = var.ecr_role_name
  roles      = [aws_iam_role.scanning[0].name]
  policy_arn = aws_iam_policy.lambda_scanning[0].arn
}
