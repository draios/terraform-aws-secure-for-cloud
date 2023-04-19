#-----------------------------------------------------------------------------------------------------------------------
# These resources set up an EventBridge Rule and Target to forward all CloudTrail events from the source account to
# Sysdig in all accounts in an AWS Organization via a CloudFormation StackSet. For a single account installation, see
# main.tf.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "org" {
  count = var.is_organizational ? 1 : 0
}

data "aws_region" "current" {}

locals {
  organizational_unit_ids = var.is_organizational && length(var.organization_units) == 0 ? [for root in data.aws_organizations_organization.org[0].roots : root.id] : toset(var.organization_units)
  region_set              = length(var.regions) == 0 ? [data.aws_region.current.name] : toset(var.regions)
}

# permission policy for stackset admin role
resource "aws_iam_policy" "admin_role_policy" {
  count  = var.is_organizational ? 1 : 0
  name   = "stackset-admin-role-policy"
  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Action": [
                "sts:AssumeRole"
            ],
            "Resource": [
                "arn:*:iam::*:role/AWSCloudFormationStackSetExecutionRole"
            ],
            "Effect": "Allow"
        }
    ]
}
EOF
}

# policy attachment for stackset admin role
resource "aws_iam_policy_attachment" "admin_role_attachment" {
  count      = var.is_organizational ? 1 : 0
  policy_arn = aws_iam_policy.admin_role_policy[0].arn
  roles      = [aws_iam_role.mgmt_stackset_admin_role[0].name]
  name       = "stackset-admin-role-policy-attachment"
}

# admin role needed to deploy resources in management account via stackset
resource "aws_iam_role" "mgmt_stackset_admin_role" {
  count = var.is_organizational ? 1 : 0

  name = "AWSCloudFormationStackSetAdministrationRole"
  tags = var.tags

  assume_role_policy = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Service": "cloudformation.amazonaws.com"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
}

# execution role needed to deploy resources in management account via stackset
resource "aws_iam_role" "mgmt_stackset_execution_role" {
  count = var.is_organizational ? 1 : 0

  name = "AWSCloudFormationStackSetExecutionRole"
  tags = var.tags

  assume_role_policy  = <<EOF
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "AWS": "${aws_iam_role.mgmt_stackset_admin_role[0].unique_id}"
            },
            "Action": "sts:AssumeRole"
        }
    ]
}
EOF
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

# stackset to deploy eventbridge rule in organization unit
resource "aws_cloudformation_stack_set" "eb-rule-stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.name, "EBRuleOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = <<TEMPLATE
Resources:
  EventBridgeRule:
    Type: AWS::Events::Rule
    Properties:
      Name: ${var.name}
      Description: Capture all CloudTrail events
      EventPattern:
        detail-type:
          - 'AWS API Call via CloudTrail'
          - 'AWS Console Sign In via CloudTrail'
          - 'AWS Service Event via CloudTrail'
      Targets:
        - Id: ${var.name}
          Arn: ${var.target_event_bus_arn}
          RoleArn: !Sub "arn:aws:iam::$${AWS::AccountId}:role/${var.name}"
TEMPLATE
}

# stackset to deploy eventbridge rule in management account
resource "aws_cloudformation_stack_set" "mgmt-stackset" {
  count = var.is_organizational ? 1 : 0

  name                    = join("-", [var.name, "EBRuleMgmtAcc"])
  tags                    = var.tags
  permission_model        = "SELF_MANAGED"
  capabilities            = ["CAPABILITY_NAMED_IAM"]
  administration_role_arn = aws_iam_role.mgmt_stackset_admin_role[0].arn
  depends_on              = [aws_iam_role.mgmt_stackset_execution_role[0]]

  template_body = <<TEMPLATE
Resources:
  EventBridgeRule:
    Type: AWS::Events::Rule
    Properties:
      Name: ${var.name}
      Description: Capture all CloudTrail events
      EventPattern:
        detail-type:
          - 'AWS API Call via CloudTrail'
          - 'AWS Console Sign In via CloudTrail'
          - 'AWS Service Event via CloudTrail'
      Targets:
        - Id: ${var.name}
          Arn: ${var.target_event_bus_arn}
          RoleArn: ${aws_iam_role.event_bus_invoke_remote_event_bus[0].arn}
TEMPLATE
}

# stackset to deploy eventbridge role in organization unit
resource "aws_cloudformation_stack_set" "eb-role-stackset" {
  count = var.is_organizational ? 1 : 0

  name             = join("-", [var.name, "EBRoleOrg"])
  tags             = var.tags
  permission_model = "SERVICE_MANAGED"
  capabilities     = ["CAPABILITY_NAMED_IAM"]

  auto_deployment {
    enabled                          = true
    retain_stacks_on_account_removal = false
  }

  template_body = <<TEMPLATE
Resources:
  EventBridgeRole:
      Type: AWS::IAM::Role
      Properties:
        RoleName: ${var.name}
        AssumeRolePolicyDocument:
          Version: "2012-10-17"
          Statement:
            - Effect: Allow
              Principal:
                Service: events.amazonaws.com
              Action: 'sts:AssumeRole'
            - Effect: "Allow"
              Principal:
                AWS: "${var.trusted_identity}"
              Action: "sts:AssumeRole"
              Condition:
                StringEquals:
                  sts:ExternalId: "${var.external_id}"
        Policies:
          - PolicyName: ${var.name}
            PolicyDocument:
              Version: "2012-10-17"
              Statement:
                - Effect: Allow
                  Action: 'events:PutEvents'
                  Resource: ${var.target_event_bus_arn}
TEMPLATE
}

// stackset instance to deploy rule in all organization units
resource "aws_cloudformation_stack_set_instance" "stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.eb-rule-stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}

// stackset instance to deploy rule in all regions of management account
resource "aws_cloudformation_stack_set_instance" "mgmt_acc_stackset_instance" {
  for_each       = local.region_set
  region         = each.key
  stack_set_name = aws_cloudformation_stack_set.mgmt-stackset[0].name

  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}

// stackset instance to deploy role in all organization units
resource "aws_cloudformation_stack_set_instance" "eb_role_stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.eb-role-stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 10
    max_concurrent_count    = 10
    region_concurrency_type = "PARALLEL"
  }
}
