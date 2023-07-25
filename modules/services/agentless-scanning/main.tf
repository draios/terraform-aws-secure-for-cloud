##################################
# Controller IAM roles and stuff #
##################################

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
# These resources create an Agentless Scanning IAM Role, IAM Policy, KMS keys and KMS Aliases in the account.
# For the KMS key resource - a KMS Primary key is created in the primary region, an Alias for this key in that region.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_iam_policy_document" "agentless" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  # General read permission, necessary for the discovery phase.
  statement {
    sid = "Read"

    actions = [
      "ec2:Describe*",
    ]

    resources = [
      "*",
    ]
  }

  # Allow the listing of KMS keys, necessary to find the right one.
  statement {
    sid = "AllowKMSKeysListing"

    actions = [
      "kms:ListKeys",
      "kms:ListAliases",
      "kms:ListResourceTags",
    ]

    resources = [
      "*",
    ]
  }

  # Allows the creation of snapshots.
  statement {
    sid = "CreateTaggedSnapshotFromVolume"

    actions = [
      "ec2:CreateSnapshot",
    ]

    resources = [
      "*",
    ]
  }

  # Allows the copy of snapshot, which is necessary for re-encrypting
  # them to make them shareable with Sysdig account.
  statement {
    sid = "CopySnapshots"

    actions = [
      "ec2:CopySnapshot",
    ]

    resources = [
      "*",
    ]
  }

  # Allows tagging snapshots only for specific tag key and value.
  statement {
    sid = "SnapshotTags"

    actions = [
      "ec2:CreateTags"
    ]

    resources = [
      "*",
    ]

    # This condition limits the scope of tagging to the sole
    # CreateSnapshot and CopySnapshot operations.
    condition {
      test     = "StringEquals"
      variable = "ec2:CreateAction"
      values = [
        "CreateSnapshot",
        "CopySnapshot",
      ]
    }

    # This condition limits the value of CreatedBy tag to the exact
    # string Sysdig.
    condition {
      test     = "StringEquals"
      variable = "aws:RequestTag/CreatedBy"
      values   = ["Sysdig"]
    }
  }

  # This statement allows the modification of those snapshot that have
  # a simple "CreatedBy" tag valued "Sysdig". Additionally, such
  # snapshots can only be shared with a specific AWS account, namely
  # Sysdig account.
  statement {
    sid = "ec2SnapshotShare"

    actions = [
      "ec2:ModifySnapshotAttribute",
    ]

    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "aws:ResourceTag/CreatedBy"
      values   = ["Sysdig"]
    }

    condition {
      test     = "StringEquals"
      variable = "ec2:Add/userId"
      values = [
        var.agentless_account_id
      ]
    }

    resources = [
      "*",
    ]
  }

  statement {
    sid = "ec2SnapshotDelete"

    actions = [
      "ec2:DeleteSnapshot",
    ]

    condition {
      test     = "StringEqualsIgnoreCase"
      variable = "aws:ResourceTag/CreatedBy"
      values   = ["Sysdig"]
    }

    resources = [
      "*",
    ]
  }
}

resource "aws_iam_policy" "agentless" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  name        = var.name
  description = "Grants Sysdig Secure access to volumes and snapshots"
  policy      = data.aws_iam_policy_document.agentless[0].json
  tags        = var.tags
}

data "aws_iam_policy_document" "agentless_assume_role_policy" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  statement {
    sid = "SysdigSecureAgentless"

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

resource "aws_iam_role" "agentless" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  name               = var.name
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.agentless_assume_role_policy[0].json
}

resource "aws_iam_policy_attachment" "agentless" {
  count = (var.deploy_global_resources || var.is_organizational) ? 1 : 0

  name       = var.name
  roles      = [aws_iam_role.agentless[0].name]
  policy_arn = aws_iam_policy.agentless[0].arn
}

# Fetch KMS key policy data only if singleton account and deploy_global_resources is true
data "aws_iam_policy_document" "key_policy" {
  count = (var.is_organizational) ? 0 : 1

  statement {
    sid = "SysdigAllowKms"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${var.agentless_account_id}:root",
        var.trusted_identity,
        (var.deploy_global_resources) ? aws_iam_role.agentless[0].arn : var.main_region_agentless_role_arn,
      ]
    }

    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
      "kms:CreateGrant",
      "kms:ListGrants",
    ]

    resources = [
      "*"
    ]
  }

  statement {
    sid = "AllowCustomerManagement"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.account_id}:root",
        local.caller_arn,
      ]
    }

    actions = [
      "kms:*"
    ]

    resources = [
      "*"
    ]
  }
}

# KMS primary key resource only if singleton account
resource "aws_kms_key" "agentless" {
  count = var.is_organizational ? 0 : 1

  description             = "Sysdig Agentless encryption primary key"
  deletion_window_in_days = var.kms_key_deletion_window
  key_usage               = "ENCRYPT_DECRYPT"
  policy                  = data.aws_iam_policy_document.key_policy[0].json
  tags                    = var.tags
}

# KMS alias resource only if singleton account
resource "aws_kms_alias" "agentless" {
  count = var.is_organizational ? 0 : 1

  name          = "alias/${var.kms_key_alias}"
  target_key_id = aws_kms_key.agentless[0].key_id
}
