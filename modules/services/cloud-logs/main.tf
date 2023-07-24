#-----------------------------------------------------------------------------------------------------------------------
# Provider setup, the region is provided through a Terraform variable and has a default value.
#-----------------------------------------------------------------------------------------------------------------------
provider "aws" {
  region = var.region
}

#-----------------------------------------------------------------------------------------------------------------------
# The only resource needed to make cloudingestion start to fetch data from the CloudTrail associated s3 bucket is a
# properly set AWS IAM Role. Sysdig's trusted identity act as the Principal in the assume role Policy, namely the role
# that CloudIngestion will use to assume the Client's role. At that point, given the permission set granted to the newly
# created Role in the Client's account, CloudIngestion will be able to perform all the required actions in order to
# list and fetch the log files that are automatically published in the target s3 bucket.
#
# Note: this setup assumes that the Client has already properly set up an AWS CloudTrail Trail and the associated bucket.
# It is responsibility of Sysdig's Secure UI to provide the necessary information to make the Client perform the
# necessary operations before applying the Terraform module.
#-----------------------------------------------------------------------------------------------------------------------

# AWS IAM Role that will be used by CloudIngestion to access the CloudTrail-associated s3 bucket
resource "aws_iam_role" "cloudlogs_access" {
  name               = var.role_name
  tags               = var.tags
  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "AssumeRoleFromSysdig",
            "Effect": "Allow",
            "Principal": {
                "AWS": "${var.trusted_identity}"
            },
            "Action": "sts:AssumeRole",
            "Condition": {
                "StringEquals": {
                    "sts:ExternalId": "${var.external_id}"
                }
            }
        }
    ]
}
EOF

  inline_policy {
    name = "cloudlogs_s3_access_policy"

    policy = jsonencode({
      "Version" : "2012-10-17",
      "Statement" : [
        {
          "Sid" : "CloudlogsS3Access",
          "Effect" : "Allow",
          "Action" : [
            "s3:Get*",
            "s3:List*",
          ],
          "Resource" : [
            "arn:aws:s3:::${var.bucket_name}",
            "arn:aws:s3:::${var.bucket_name}/*"
          ]
        }
      ]
    })
  }
}
