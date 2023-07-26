#-----------------------------------------------------------------------------------------------------------------------
# The only resource needed to make cloudingestion start to fetch data from the CloudTrail associated s3 bucket is a
# properly set AWS IAM Role. Sysdig's trusted identity act as the Principal in the assume role Policy, namely the role
# that CloudIngestion will use to assume the Client's role. At that point, given the permission set granted to the newly
# created Role in the Client's account, CloudIngestion will be able to perform all the required actions in order to
# list and fetch the log files that are automatically published in the target s3 bucket.
#
# Note: this setup assumes that the Customer has already properly set up an AWS CloudTrail Trail and the associated bucket.
# It is responsibility of Sysdig's Secure UI to provide the necessary information to make the Customer perform the
# necessary operations before applying the Terraform module.
#-----------------------------------------------------------------------------------------------------------------------

# AWS IAM Role that will be used by CloudIngestion to access the CloudTrail-associated s3 bucket
resource "aws_iam_role" "cloudlogs_s3_access" {
  name = var.role_name
  tags = var.tags

  assume_role_policy = data.aws_iam_policy_document.assume_cloudlogs_s3_access_role.json
  inline_policy {
    name   = "cloudlogs_s3_access_policy"
    policy = data.aws_iam_policy_document.cloudlogs_s3_access_policy.json
  }
}

# IAM Policy Document used for the assume role policy
data "aws_iam_policy_document" "assume_cloudlogs_s3_access_role" {
  statement {
    effect = "Allow"

    principals {
      type        = "AWS"
      identifiers = [var.trusted_identity]
    }

    actions = ["sts:AssumeRole"]

    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

# IAM Policy Document used for the bucket access policy
data "aws_iam_policy_document" "cloudlogs_s3_access_policy" {

  statement {
    sid = "CloudlogsS3Access"

    effect = "Allow"

    actions = [
      "s3:Get*",
      "s3:List*"
    ]

    resources = [
      "arn:aws:s3:::${var.bucket_name}",
      "arn:aws:s3:::${var.bucket_name}/*"
    ]
  }
}
