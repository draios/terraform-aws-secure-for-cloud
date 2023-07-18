#-----------------------------------------------------------------------------------------------------------------------
# Determine if this is an Organizational install, or a single account install. For Organizational installs, resources
# are created using CloudFormation StackSet. For Single Account installs see main.tf.
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# We have two types of resources. global and regional. Global resources are deployed only once. (mostly in the primary
# region). We use deploy_global_resources boolean to determine that.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

locals {
  organizational_unit_ids = var.is_organizational && length(var.org_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : toset(var.org_units)
  region_set              = toset(var.instrumented_regions)
}

#-----------------------------------------------------------------------------------------------------------------------
# The resources in this file set up an Agentless Scanning IAM Role, Policies, KMS keys and KMS Aliases in all accounts
# in an AWS Organization via a CloudFormation StackSet. For the KMS key resource -
# a KMS Primary key is created in the primary region, an Alias for this key in the primary region,
# a KMS Replica Key in each additional region, and an Alias in each additional region.
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed in organization unit for Agentless Scanning IAM Role, Policies
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy agentless scanning role in organization unit
resource "aws_cloudformation_stack_set" "scanning_role_stackset" {
  count = (var.is_organizational && var.deploy_global_resources) ? 1 : 0

  name             = join("-", [var.name, "ScanningRoleOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
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
            - Sid: "SysdigSecureAgentless"
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
                  Action:
                    - "ec2:Describe*"
                  Resource: "*"
                - Sid: "AllowKMSKeysListing"
                  Effect: "Allow"
                  Action:
                    - "kms:ListKeys"
                    - "kms:ListAliases"
                    - "kms:ListResourceTags"
                  Resource: "*"
                - Sid: "CreateTaggedSnapshotFromVolume"
                  Effect: "Allow"
                  Action:
                    - "ec2:CreateSnapshot"
                  Resource: "*"
                - Sid: "CopySnapshots"
                  Effect: "Allow"
                  Action:
                    - "ec2:CopySnapshot"
                  Resource: "*"
                - Sid: "SnapshotTags"
                  Effect: "Allow"
                  Action:
                    - "ec2:CreateTags"
                  Resource: "*"
                  Condition:
                    - StringEquals:
                        ec2:CreateAction: ["CreateSnapshot", "CopySnapshot"]
                    - StringEquals:
                        aws:RequestTag/CreatedBy: "Sysdig"
                - Sid: "ec2SnapshotShare"
                  Effect: "Allow"
                  Action:
                    - "ec2:ModifySnapshotAttribute"
                  Resource: "*"
                  Condition:
                    - StringEqualsIgnoreCase:
                        aws:ResourceTag/CreatedBy: "Sysdig"
                    - StringEquals:
                        ec2:Add/userId: "${var.agentless_account_id}"
                - Sid: "ec2SnapshotDelete"
                  Effect: "Allow"
                  Action:
                    - "ec2:DeleteSnapshot"
                  Resource: "*"
                  Condition:
                    - StringEqualsIgnoreCase:
                        aws:ResourceTag/CreatedBy: "Sysdig"

TEMPLATE
}

# stackset instance to deploy agentless scanning role in all organization units
resource "aws_cloudformation_stack_set_instance" "scanning_role_stackset_instance" {
  count = (var.is_organizational && var.deploy_global_resources) ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.scanning_role_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance for management account - global resources (deployed only once, in primary region)
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy global resources for agentless scanning in management account
resource "aws_cloudformation_stack_set" "mgmt_acc_resources_stackset" {
  count = var.is_organizational ? 1 : 0

  name                    = var.deploy_global_resources ? join("-", [var.name, "ScanningKmsMgmtAccGlobal"]) : join("-", [var.name, "ScanningKmsMgmtAccNonGlobal"])
  tags                    = var.tags
  permission_model        = "SELF_MANAGED"
  capabilities            = ["CAPABILITY_NAMED_IAM"]
  administration_role_arn = var.stackset_admin_role_arn

  template_body = <<TEMPLATE
Conditions:
  IsGlobal: !Equals
    - ${var.deploy_global_resources}
    - true
  IsNotGlobal: !Equals
    - ${var.deploy_global_resources}
    - false
Resources:
  AgentlessScanningKmsPrimaryKey:
      Condition: IsGlobal
      Type: AWS::KMS::Key
      Properties:
        Description: "Sysdig Agentless encryption primary key"
        MultiRegion: true
        PendingWindowInDays: ${var.kms_key_deletion_window}
        KeyUsage: "ENCRYPT_DECRYPT"
        KeyPolicy:
          Id: ${var.name}
          Statement:
            - Sid: "SysdigAllowKms"
              Effect: "Allow"
              Principal:
                AWS: ["arn:aws:iam::${var.agentless_account_id}:root", "${var.trusted_identity}", !Sub "arn:aws:iam::$${AWS::AccountId}:role/${var.name}"]
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
              Action:
                - "kms:*"
              Resource: "*"
  AgentlessScanningKmsPrimaryAlias:
      Condition: IsGlobal
      Type: AWS::KMS::Alias
      Properties:
        AliasName: "alias/${var.kms_key_alias}"
        TargetKeyId: !GetAtt AgentlessScanningKmsPrimaryKey.KeyId
  AgentlessScanningKmsReplicaKey:
      Condition: IsNotGlobal
      Type: AWS::KMS::ReplicaKey
      Properties:
        Description: "Sysdig Agentless multi-region replica key"
        PendingWindowInDays: ${var.kms_key_deletion_window}
        KeyPolicy: ""
        PrimaryKeyArn: !GetAtt AgentlessScanningKmsPrimaryKey.Arn
  AgentlessScanningKmsReplicaAlias:
      Condition: IsNotGlobal
      Type: AWS::KMS::Alias
      Properties:
        AliasName: "alias/${var.kms_key_alias}"
        TargetKeyId: !GetAtt AgentlessScanningKmsPrimaryKey.KeyId

TEMPLATE
}

# stackset instance to deploy global resources (in primary region) for agentless scanning in management account
resource "aws_cloudformation_stack_set_instance" "mgmt_acc_global_stackset_instance" {
  count = (var.is_organizational && var.deploy_global_resources) ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.mgmt_acc_resources_stackset[0].name
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
  }
}

# stackset instance to deploy global resources (in primary region) for agentless scanning in management account
resource "aws_cloudformation_stack_set_instance" "mgmt_acc_nonglobal_stackset_instance" {
  for_each = local.region_set
  region   = !var.deploy_global_resources ? each.key : ""

  stack_set_name = aws_cloudformation_stack_set.mgmt_acc_resources_stackset[0].name
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed in organization units - global resources
# (deployed once per account, in primary region)
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy global resources for agentless scanning in organization unit
resource "aws_cloudformation_stack_set" "ou_resources_stackset" {
  count = var.is_organizational ? 1 : 0

  name             = var.deploy_global_resources ? join("-", [var.name, "ScanningKmsOrgGlobal"]) : join("-", [var.name, "ScanningKmsOrgNonGlobal"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = <<TEMPLATE
Conditions:
  IsGlobal: !Equals
    - ${var.deploy_global_resources}
    - true
  IsNotGlobal: !Equals
    - ${var.deploy_global_resources}
    - false
Resources:
  AgentlessScanningKmsPrimaryKey:
      Condition: IsGlobal
      Type: AWS::KMS::Key
      Properties:
        Description: "Sysdig Agentless encryption primary key"
        MultiRegion: true
        PendingWindowInDays: ${var.kms_key_deletion_window}
        KeyUsage: "ENCRYPT_DECRYPT"
        KeyPolicy:
          Id: ${var.name}
          Statement:
            - Sid: "SysdigAllowKms"
              Effect: "Allow"
              Principal:
                AWS: ["arn:aws:iam::${var.agentless_account_id}:root", "${var.trusted_identity}", !Sub "arn:aws:iam::$${AWS::AccountId}:role/${var.name}"]
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
              Action:
                - "kms:*"
              Resource: "*"
  AgentlessScanningKmsPrimaryAlias:
      Condition: IsGlobal
      Type: AWS::KMS::Alias
      Properties:
        AliasName: "alias/${var.kms_key_alias}"
        TargetKeyId: !GetAtt AgentlessScanningKmsPrimaryKey.KeyId
  AgentlessScanningKmsReplicaKey:
      Condition: IsNotGlobal
      Type: AWS::KMS::ReplicaKey
      Properties:
        Description: "Sysdig Agentless multi-region replica key"
        PendingWindowInDays: ${var.kms_key_deletion_window}
        KeyPolicy: ""
        PrimaryKeyArn: !GetAtt AgentlessScanningKmsPrimaryKey.Arn
  AgentlessScanningKmsReplicaAlias:
      Condition: IsNotGlobal
      Type: AWS::KMS::Alias
      Properties:
        AliasName: "alias/${var.kms_key_alias}"
        TargetKeyId: !GetAtt AgentlessScanningKmsPrimaryKey.KeyId

TEMPLATE
}

# stackset instance to deploy global resources (in primary region) for agentless scanning in all organization units
resource "aws_cloudformation_stack_set_instance" "ou_global_stackset_instance" {
  count = (var.is_organizational && var.deploy_global_resources) ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.ou_resources_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
  }
}

# stackset instance to deploy global resources (in primary region) for agentless scanning in all organization units
resource "aws_cloudformation_stack_set_instance" "ou_nonglobal_stackset_instance" {
  for_each = local.region_set
  region   = !var.deploy_global_resources ? each.key : ""

  stack_set_name = aws_cloudformation_stack_set.ou_resources_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}