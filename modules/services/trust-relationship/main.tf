#----------------------------------------------------------
# Fetch & compute required data
#----------------------------------------------------------

data "aws_caller_identity" "me" {}

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

locals {
  caller_account      = data.aws_caller_identity.me.account_id
  org_units_to_deploy = var.is_organizational && length(var.org_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : var.org_units
  member_account_ids  = var.is_organizational ? [for a in data.aws_organizations_organization.org[0].non_master_accounts : a.id] : []
}

#----------------------------------------------------------
# If this is not an Organizational deploy, create role/polices directly
#----------------------------------------------------------
resource "aws_iam_role" "cspm_role" {
  name                = var.role_name
  tags                = var.tags
  assume_role_policy  = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Sid": "",
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
  managed_policy_arns = ["arn:aws:iam::aws:policy/SecurityAudit"]
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
