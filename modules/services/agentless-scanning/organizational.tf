#-----------------------------------------------------------------------------------------------------------------------
# Determine if this is an Organizational install, or a single account install. For Organizational installs, resources
# are created using CloudFormation StackSet. For Single Account installs see main.tf.
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# We have two types of resources. global and regional. Global resources are deployed only once.
# we use deploy_global_resources boolean to determine that.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

locals {
  organizational_unit_ids = var.is_organizational && length(var.org_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : toset(var.org_units)
}

#-----------------------------------------------------------------------------------------------------------------------
# The resources in this file set up an Agentless Scanning IAM Role, Policies, KMS keys and KMS Alias in all accounts in
# an AWS Organization via a CloudFormation StackSet. For the KMS key resource -
# a KMS key is created in the primary region, an Alias for this key in the primary region,
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
          Statement:
            - Sid: SysdigSecureAgentless
              Effect: Allow
              Action:
                - "sts:AssumeRole"
              Principal:
                AWS: "${var.trusted_identity}"
              Condition:
                StringEquals:
                  sts:ExternalId: "${var.external_id}"
        Policies:
          - PolicyName: ${var.name}
            PolicyDocument:
              Statement:
                - Sid: Read
                  Effect: Allow
                  Action:
                    - "ec2:Describe*"
                  Resource:
                    - "*"
                - Sid: AllowKMSKeysListing
                  Effect: Allow
                  Action:
                    - "kms:ListKeys"
                    - "kms:ListAliases"
                    - "kms:ListResourceTags"
                  Resource:
                    - "*"
                - Sid: CreateTaggedSnapshotFromVolume
                  Effect: Allow
                  Action:
                    - "ec2:CreateSnapshot"
                  Resource:
                    - "*"
                - Sid: CopySnapshots
                  Effect: Allow
                  Action:
                    - "ec2:CopySnapshot"
                  Resource:
                    - "*"
                - Sid: SnapshotTags
                  Effect: Allow
                  Action:
                    - "ec2:CreateTags"
                  Resource:
                    - "*"
                  Condition:
                    - StringEquals:
                        ec2:CreateAction: ["CreateSnapshot", "CopySnapshot"]
                    - StringEquals:
                        aws:RequestTag/CreatedBy: "Sysdig"
                - Sid: ec2SnapshotShare
                  Effect: Allow
                  Action:
                    - "ec2:ModifySnapshotAttribute"
                  Resource:
                    - "*"
                  Condition:
                    - StringEqualsIgnoreCase:
                        aws:ResourceTag/CreatedBy: "Sysdig"
                    - StringEquals:
                        ec2:Add/userId: "${var.agentless_account_id}"
                - Sid: ec2SnapshotDelete
                  Effect: Allow
                  Action:
                    - "ec2:DeleteSnapshot"
                  Resource:
                    - "*"
                  Condition:
                    - StringEqualsIgnoreCase:
                        aws:ResourceTag/CreatedBy: "Sysdig"
                  
TEMPLATE
}

// stackset instance to deploy role in all organization units
resource "aws_cloudformation_stack_set_instance" "scanning_role_stackset_instance" {
  count = (var.is_organizational && var.deploy_global_resources) ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.scanning_role_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed in organization unit for KMS Primary Key
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy multi-region KMS primary key in organization unit for agentless scanning
resource "aws_cloudformation_stack_set" "kms_primary_key_stackset" {
  count = (var.is_organizational && var.deploy_global_resources) ? 1 : 0

  name             = join("-", [var.name, "ScanningKmsPrimaryKeyOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = <<TEMPLATE
Resources:
  AgentlessScanningKmsPrimaryKey:
      Type: AWS::KMS::Key
      Properties:
        Description: "Sysdig Agentless encryption primary key"
        DeletionWindowInDays: "${var.kms_key_deletion_window}"
        KeyUsage: "ENCRYPT_DECRYPT"
        MultiRegion: true
        Tags: var.tags
        Policies:
          - PolicyName: ${var.name}
            PolicyDocument:
              Statement:
                - Sid: SysdigAllowKms
                  Principal:
                    AWS: ["arn:aws:iam::${var.agentless_account_id}:root", "${var.trusted_identity}", !Ref 'aws_cloudformation_stack_set.scanning_role_stackset[0].arn']
                  Action:
                    - "kms:Encrypt"
                    - "kms:Decrypt"
                    - "kms:ReEncrypt*"
                    - "kms:GenerateDataKey*"
                    - "kms:DescribeKey"
                    - "kms:CreateGrant"
                    - "kms:ListGrants"
                  Resource:
                    - "*"
                - Sid: AllowCustomerManagement
                  Principal:
                    AWS: ["arn:aws:iam::${local.account_id}:root", "${local.caller_arn}"]
                  Action:
                    - "kms:*"
                  Resource:
                    - "*"

TEMPLATE
}

// stackset instance to deploy KMS primary key in primary region of all organization units
resource "aws_cloudformation_stack_set_instance" "kms_primary_key_stackset_instance" {
  count = (var.is_organizational && var.deploy_global_resources) ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.kms_primary_key_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed in organization unit for KMS Replica Key
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy multi-region KMS replica key in organization unit for agentless scanning
resource "aws_cloudformation_stack_set" "kms_replica_key_stackset" {
  count = (var.is_organizational && !var.deploy_global_resources) ? 1 : 0

  name             = join("-", [var.name, "ScanningKmsReplicaKeyOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = <<TEMPLATE
Resources:
  AgentlessScanningKmsReplicaKey:
      Type: AWS::KMS::ReplicaKey
      Properties:
        Description: "Sysdig Agentless multi-region replica key"
        DeletionWindowInDays: "${var.kms_key_deletion_window}"
        PrimaryKeyArn: "${var.primary_key.arn}"

TEMPLATE
}

// stackset instance to deploy KMS replica key in additional regions of all organization units
resource "aws_cloudformation_stack_set_instance" "kms_replica_key_stackset_instance" {
  count = (var.is_organizational && !var.deploy_global_resources) ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.kms_replica_key_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# stackset and stackset instance deployed in organization unit for KMS Key Alias for primary and additional regions
#-----------------------------------------------------------------------------------------------------------------------

# stackset to deploy multi-region KMS key Alias in organization unit for agentless scanning
resource "aws_cloudformation_stack_set" "kms_key_alias_stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.name, "ScanningKmsKeyAliasOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = <<TEMPLATE
Conditions:
  IsGlobalResource: !Equals
    - "${var.deploy_global_resources}"
    - "true"

Resources:
  AgentlessScanningKmsKeyAlias:
      Type: AWS::KMS::Alias
      Properties:
        AliasName: "alias/${var.kms_key_alias}"
        TargetKeyId: !If [IsGlobalResource, !Ref 'aws_cloudformation_stack_set.kms_primary_key_stackset[0].key_id', "${var.primary_key.id}"]

TEMPLATE
}

// stackset instance to deploy KMS Key Alias in all organization units
resource "aws_cloudformation_stack_set_instance" "kms_key_alias_stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.kms_key_alias_stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}