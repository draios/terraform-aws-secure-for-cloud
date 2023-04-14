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
  excluded_region         = data.aws_region.current.name
  updated_regions         = setsubtract(var.regions, [local.excluded_region])
}

resource "aws_iam_role" "mgmt_stackset_admin_role" {
  count = var.is_organizational ? 1 : 0

  name = "AWSCloudFormationStackSetAdministrationRole"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "cloudformation.amazonaws.com"
        }
        Resource = "arn:*:iam::*:role/AWSCloudFormationStackSetExecutionRole"
      },
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = var.trusted_identity
        }
        Resource = "arn:*:iam::*:role/AWSCloudFormationStackSetExecutionRole"
        Condition = {
          StringEquals = {
            "sts:ExternalId" = var.external_id
          }
        }
      }
    ]
  })

  //  assume_role_policy = <<EOF
  //{
  //  "Version": "2012-10-17",
  //  "Statement": [
  //    {
  //      "Action": "sts:AssumeRole",
  //      "Principal": {
  //        "Service": "cloudformation.amazonaws.com"
  //      },
  //      "Resource": {
  //        "arn:*:iam::*:role/AWSCloudFormationStackSetExecutionRole"
  //      },
  //      "Effect": "Allow"
  //    },
  //    {
  //      "Action": "sts:AssumeRole",
  //      "Principal": {
  //        "AWS": "${var.trusted_identity}"
  //      },
  //      "Effect": "Allow",
  //      "Condition": {
  //        "StringEquals": {
  //          "sts:ExternalId": "${var.external_id}"
  //        }
  //      }
  //    }
  //  ]
  //}
  //EOF
}

resource "aws_iam_role" "mgmt_stackset_execution_role" {
  count = var.is_organizational ? 1 : 0

  name = "AWSCloudFormationStackSetExecutionRole"
  tags = var.tags

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          AWS = aws_iam_role.mgmt_stackset_admin_role[0].arn
        }
      }
    ]
  })
  managed_policy_arns = ["arn:aws:iam::aws:policy/AdministratorAccess"]
}

resource "aws_cloudformation_stack_set" "stackset" {
  count = var.is_organizational ? 1 : 0

  name             = var.name
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
          RoleArn: ${aws_iam_role.event_bus_invoke_remote_event_bus[0].arn}
TEMPLATE
}

resource "aws_cloudformation_stack_set" "mgmt-stackset" {
  count = var.is_organizational ? 1 : 0

  name                    = var.name
  tags                    = var.tags
  permission_model        = "SELF_MANAGED"
  capabilities            = ["CAPABILITY_NAMED_IAM"]
  administration_role_arn = aws_iam_role.mgmt_stackset_admin_role[0].arn

  //  auto_deployment {
  //    enabled                          = true
  //    retain_stacks_on_account_removal = false
  //  }

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

// stackset instance to deploy rule in all organization units
resource "aws_cloudformation_stack_set_instance" "stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
  operation_preferences {
    failure_tolerance_count = 5
    max_concurrent_count    = 2
  }
}

// stackset instance to deploy rule in all regions of management account
resource "aws_cloudformation_stack_set_instance" "mgmt_acc_stackset_instance" {
  for_each       = toset(local.updated_regions)
  region         = each.key
  stack_set_name = aws_cloudformation_stack_set.mgmt-stackset[0].name

  operation_preferences {
    failure_tolerance_count = 5
    max_concurrent_count    = 2
  }
}
