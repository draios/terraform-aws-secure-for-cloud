##################################
# Controller IAM roles and stuff #
##################################

data "aws_iam_policy_document" "agentless" {
  count = var.deploy_global_resources ? 1 : 0

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
        local.agentless_account_id
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
  count = var.deploy_global_resources ? 1 : 0

  name        = var.name
  path        = "/sysdig/secure/agentless/"
  description = "Grants Sysdig Secure access to volumes and snapshots"
  policy      = data.aws_iam_policy_document.agentless[0].json
  tags        = var.tags
}

data "aws_iam_policy_document" "agentless_assume_role_policy" {
  count = var.deploy_global_resources ? 1 : 0

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
  count = var.deploy_global_resources ? 1 : 0

  name               = var.name
  tags               = var.tags
  assume_role_policy = data.aws_iam_policy_document.agentless_assume_role_policy[0].json
}

resource "aws_iam_policy_attachment" "agentless" {
  count = var.deploy_global_resources ? 1 : 0

  name       = "sysdig-agentless-host-scanning"
  roles      = [aws_iam_role.agentless[0].name]
  policy_arn = aws_iam_policy.agentless[0].arn
}

data "aws_iam_policy_document" "key_policy" {
  count = var.deploy_global_resources ? 1 : 0

  statement {
    sid = "SysdigAllowKms"

    principals {
      type = "AWS"
      identifiers = [
        "arn:aws:iam::${local.agentless_account_id}:root",
        var.trusted_identity,
        aws_iam_role.agentless[0].arn,
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

resource "aws_kms_key" "agentless" {
  count = var.deploy_global_resources ? 1 : 0

  description             = "Sysdig Agentless encryption key"
  deletion_window_in_days = var.kms_key_deletion_window
  key_usage               = "ENCRYPT_DECRYPT"
  policy                  = data.aws_iam_policy_document.key_policy[0].json
  multi_region            = true
  tags                    = var.tags
}

resource "aws_kms_replica_key" "agentless_replica" {
  count = var.deploy_global_resources ? 0 : 1

  description             = "Sysdig Agentless multi-region replica key"
  deletion_window_in_days = 7
  primary_key_arn         = var.primary_key.arn
}

resource "aws_kms_alias" "agentless" {
  name          = "alias/${var.kms_key_alias}"
  target_key_id = var.deploy_global_resources ? aws_kms_key.agentless[0].key_id : var.primary_key.id
}
