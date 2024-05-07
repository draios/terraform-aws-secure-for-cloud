#-----------------------------------------------------------------------------------------------------------------------
# Determine if this is an Organizational install, or a single account install. For Organizational installs, resources
# are created using CloudFormation StackSet. For Single Account installs see main.tf.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

locals {
  organizational_unit_ids = var.is_organizational && length(var.org_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : toset(var.org_units)
  region_set              = toset(var.regions)
}

#-----------------------------------------------------------------------------------------------------------------------
# The resources in this file set up an Agentless Scanning IAM Role, Policies, KMS keys and KMS Aliases in all accounts
# in an AWS Organization via a CloudFormation StackSet.
# Global resources: IAM Role and Policy
# Non-global / Regional resources:
# - a KMS Primary key is created, in each region of region list,
# - an Alias by the same name for the respective key, in each region of region list.
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed in organization units for Agentless Scanning IAM Role, Policies
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy agentless scanning role in organization unit
resource "aws_cloudformation_stack_set" "scanning_role_stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.name, "ScanningRoleOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  managed_execution {
    active = true
  }

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  lifecycle {
    ignore_changes = [administration_role_arn]
  }

  template_body = <<TEMPLATE
Resources:
  AgentlessScanningRole:
      Type: AWS::IAM::Role
      Properties:
        RoleName: ${var.name}
        AssumeRolePolicyDocument:
          Version: "2012-10-17"
          Statement:
            - Sid: "SysdigSecureScanning"
              Effect: "Allow"
              Action: "sts:AssumeRole"
              Principal:
                AWS: "${var.trusted_identity}"
              Condition:
                StringEquals:
                  sts:ExternalId: "${var.external_id}"
        Policies:
          - PolicyName: ${var.name}
            PolicyDocument:
              Version: "2012-10-17"
              Statement:
                - Sid: "Read"
                  Effect: "Allow"
                  Action: "ec2:Describe*"
                  Resource: "*"
                - Sid: "AllowKMSKeysListing"
                  Effect: "Allow"
                  Action:
                    - "kms:ListKeys"
                    - "kms:ListAliases"
                    - "kms:ListResourceTags"
                  Resource: "*"
                - Sid: "AllowKMSEncryptDecrypt"
                  Effect: "Allow"
                  Action:
                    - "kms:DescribeKey"
                    - "kms:Encrypt"
                    - "kms:Decrypt"
                    - "kms:ReEncrypt*"
                    - "kms:GenerateDataKey*"
                    - "kms:CreateGrant"
                  Resource: "*"
                  Condition:
                    StringLike:
                      kms:ViaService: ["ec2.*.amazonaws.com"]
                - Sid: "CreateTaggedSnapshotFromVolume"
                  Effect: "Allow"
                  Action: "ec2:CreateSnapshot"
                  Resource: "*"
                - Sid: "CopySnapshots"
                  Effect: "Allow"
                  Action: "ec2:CopySnapshot"
                  Resource: "*"
                - Sid: "SnapshotTags"
                  Effect: "Allow"
                  Action: "ec2:CreateTags"
                  Resource: "*"
                  Condition:
                    StringEquals:
                      ec2:CreateAction: ["CreateSnapshot", "CopySnapshot"]
                      aws:RequestTag/CreatedBy: "Sysdig"
                - Sid: "ec2SnapshotShare"
                  Effect: "Allow"
                  Action: "ec2:ModifySnapshotAttribute"
                  Resource: "*"
                  Condition:
                    StringEqualsIgnoreCase:
                      aws:ResourceTag/CreatedBy: "Sysdig"
                    StringEquals:
                      ec2:Add/userId: "${var.scanning_account_id}"
                - Sid: "ec2SnapshotDelete"
                  Effect: "Allow"
                  Action: "ec2:DeleteSnapshot"
                  Resource: "*"
                  Condition:
                    StringEqualsIgnoreCase:
                      aws:ResourceTag/CreatedBy: "Sysdig"

TEMPLATE
}

# stackset instance to deploy agentless scanning role, in all organization units
resource "aws_cloudformation_stack_set_instance" "scanning_role_stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.scanning_role_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    max_concurrent_count = 10
  }

  timeouts {
    create = var.timeout
    update = var.timeout
    delete = var.timeout
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed for management account
#   - KMS Primary Key, and
#   - KMS Primary alias
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy resources for agentless scanning in management account
resource "aws_cloudformation_stack_set" "mgmt_acc_resources_stackset" {
  count      = var.is_organizational ? 1 : 0
  depends_on = [aws_iam_role.scanning]

  name                    = join("-", [var.name, "ScanningKmsMgmtAcc"])
  tags                    = var.tags
  permission_model        = "SELF_MANAGED"
  capabilities            = ["CAPABILITY_NAMED_IAM"]
  administration_role_arn = var.stackset_admin_role_arn

  managed_execution {
    active = true
  }

  lifecycle {
    ignore_changes = [administration_role_arn]
  }

  template_body = <<TEMPLATE
Resources:
  AgentlessScanningKmsPrimaryKey:
      Type: AWS::KMS::Key
      Properties:
        Description: "Sysdig Agentless Scanning encryption key"
        PendingWindowInDays: ${var.kms_key_deletion_window}
        KeyUsage: "ENCRYPT_DECRYPT"
        KeyPolicy:
          Id: ${var.name}
          Statement:
            - Sid: "SysdigAllowKms"
              Effect: "Allow"
              Principal:
                AWS: ["arn:aws:iam::${var.scanning_account_id}:root", !Sub "arn:aws:iam::$${AWS::AccountId}:role/${var.name}"]
              Action:
                - "kms:Encrypt"
                - "kms:Decrypt"
                - "kms:ReEncrypt*"
                - "kms:GenerateDataKey*"
                - "kms:DescribeKey"
                - "kms:CreateGrant"
                - "kms:ListGrants"
              Resource: "*"
            - Sid: "AllowCustomerManagement"
              Effect: "Allow"
              Principal:
                AWS: ["arn:aws:iam::${local.account_id}:root", "${local.caller_arn}"]
              Action: "kms:*"
              Resource: "*"
  AgentlessScanningKmsPrimaryAlias:
      Type: AWS::KMS::Alias
      Properties:
        AliasName: "alias/${var.name}"
        TargetKeyId: !Ref AgentlessScanningKmsPrimaryKey

TEMPLATE
}

# stackset instance to deploy resources for agentless scanning, in all regions of the management account
resource "aws_cloudformation_stack_set_instance" "mgmt_acc_stackset_instance" {
  for_each = local.region_set
  region   = each.key

  stack_set_name = aws_cloudformation_stack_set.mgmt_acc_resources_stackset[0].name
  operation_preferences {
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }

  timeouts {
    create = var.timeout
    update = var.timeout
    delete = var.timeout
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed for all accounts in all organization units
#   - KMS Primary Key, and
#   - KMS Primary alias
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy resources for agentless scanning in organization unit
resource "aws_cloudformation_stack_set" "ou_resources_stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.name, "ScanningKmsOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  managed_execution {
    active = true
  }

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  lifecycle {
    ignore_changes = [administration_role_arn]
  }

  template_body = <<TEMPLATE
Resources:
  AgentlessScanningKmsPrimaryKey:
      Type: AWS::KMS::Key
      Properties:
        Description: "Sysdig Agentless Scanning encryption key"
        PendingWindowInDays: ${var.kms_key_deletion_window}
        KeyUsage: "ENCRYPT_DECRYPT"
        KeyPolicy:
          Id: ${var.name}
          Statement:
            - Sid: "SysdigAllowKms"
              Effect: "Allow"
              Principal:
                AWS: ["arn:aws:iam::${var.scanning_account_id}:root", !Sub "arn:aws:iam::$${AWS::AccountId}:role/${var.name}"]
              Action:
                - "kms:Encrypt"
                - "kms:Decrypt"
                - "kms:ReEncrypt*"
                - "kms:GenerateDataKey*"
                - "kms:DescribeKey"
                - "kms:CreateGrant"
                - "kms:ListGrants"
              Resource: "*"
            - Sid: "AllowCustomerManagement"
              Effect: "Allow"
              Principal:
                AWS: [!Sub "arn:aws:iam::$${AWS::AccountId}:root", "${local.caller_arn}"]
              Action:
                - "kms:*"
              Resource: "*"
  AgentlessScanningKmsPrimaryAlias:
      Type: AWS::KMS::Alias
      Properties:
        AliasName: "alias/${var.name}"
        TargetKeyId: !Ref AgentlessScanningKmsPrimaryKey

TEMPLATE
}

# stackset instance to deploy resources for agentless scanning, in all regions of each account in all organization units
resource "aws_cloudformation_stack_set_instance" "ou_stackset_instance" {
  for_each = local.region_set
  region   = each.key

  stack_set_name = aws_cloudformation_stack_set.ou_resources_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }

  timeouts {
    create = var.timeout
    update = var.timeout
    delete = var.timeout
  }
}
