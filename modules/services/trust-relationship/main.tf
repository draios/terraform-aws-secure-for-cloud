#----------------------------------------------------------
# Fetch & compute required data
#----------------------------------------------------------

data "aws_caller_identity" "me" {}

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

locals {
  caller_account = data.aws_caller_identity.me.account_id
  org_units_to_deploy   = var.is_organizational && length(var.org_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : var.org_units
  member_account_ids    = var.is_organizational ? [for a in data.aws_organizations_organization.org[0].non_master_accounts : a.id] : []
  account_ids_to_deploy = var.is_organizational && var.provision_caller_account && length(var.account_ids) == 0 ? concat(local.member_account_ids, [data.aws_organizations_organization.org[0].master_account_id]) : var.account_ids
}

#----------------------------------------------------------
# If this is not an Organizational deploy, create role/polices directly
#----------------------------------------------------------

data "aws_iam_policy" "security_audit" {
  arn = "arn:aws:iam::aws:policy/SecurityAudit"
}

data "aws_iam_policy_document" "trust_relationship" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]
    principals {
      type        = "AWS"
      identifiers = [var.trusted_identity]
    }
    condition {
      test     = "StringEquals"
      variable = "sts:ExternalId"
      values   = [var.external_id]
    }
  }
}

resource "aws_iam_role" "cspm_role" {
  count = var.is_organizational && !var.provision_caller_account ? 0 : 1

  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.trust_relationship.json
  tags               = var.tags
}


resource "aws_iam_role_policy_attachment" "cspm_security_audit" {
  count = var.is_organizational && !var.provision_caller_account ? 0 : 1

  role       = aws_iam_role.cspm_role[0].id
  policy_arn = data.aws_iam_policy.security_audit.arn
}


#----------------------------------------------------------
# If this is an Organizational deploy, use a CloudFormation StackSet
#----------------------------------------------------------

resource "aws_cloudformation_stack_set" "stackset" {
  count = var.is_organizational ? 1 : 0

  name             = var.role_name
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = <<TEMPLATE
Resources:
  SysdigCSPMRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: ${var.role_name}
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              AWS: [ ${var.trusted_identity} ]
            Action: [ 'sts:AssumeRole' ]
            Condition:
              StringEquals:
                sts:ExternalId: ${var.external_id}
      ManagedPolicyArns:
        - "arn:aws:iam::aws:policy/SecurityAudit"
TEMPLATE
}

resource "aws_cloudformation_stack_set_instance" "stackset_instance" {
  count = var.is_organizational ? 1 : 0

  region         = var.region
  stack_set_name = aws_cloudformation_stack_set.stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.org_units_to_deploy
  }
}
