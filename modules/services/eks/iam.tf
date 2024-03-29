// This is a Single Account installation. The resources are created globally (instead of regionally). 
data "aws_iam_policy_document" "ecr_pull_image" {
  statement {
    sid = "SysdigEcrPullImagePermissions"

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
}

resource "aws_iam_policy" "ecr_pull_image" {
  count = local.n

  name        = var.ecr_role_name
  description = "Allows Sysdig Secure to pull ECR images"
  policy      = data.aws_iam_policy_document.ecr_pull_image.json
  tags        = var.tags
}

data "aws_iam_policy_document" "ecr_assume_role" {
  statement {
    sid = "SysdigEcrAssumeRole"

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

resource "aws_iam_role" "ecr" {
  count = local.n

  name               = var.ecr_role_name
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.ecr_assume_role.json
}

resource "aws_iam_policy_attachment" "ecr" {
  count = local.n

  name       = var.ecr_role_name
  roles      = [aws_iam_role.ecr[0].name]
  policy_arn = aws_iam_policy.ecr_pull_image[0].arn
}
