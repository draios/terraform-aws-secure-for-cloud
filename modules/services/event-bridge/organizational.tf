#-----------------------------------------------------------------------------------------------------------------------
# These resources set up an EventBridge Rule and Target to forward all CloudTrail events from the source account to
# Sysdig in all accounts in an AWS Organization via a CloudFormation StackSet. For a single account installation, see
# main.tf.
#-----------------------------------------------------------------------------------------------------------------------

data "aws_organizations_organization" "org" {
  #  count = var.is_organizational ? 1 : 0
}

locals {
  organizational_unit_ids = var.is_organizational && length(var.organization_units) == 0 ? [for root in data.aws_organizations_organization.org.roots : root.id] : toset(var.organization_units)
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
  EventBridgeRole:
    Type: AWS::IAM::Role
    Properties:
      RoleName: ${var.name}
      AssumeRolePolicyDocument:
        Statement:
          - Effect: Allow
            Principal:
              Service: events.amazonaws.com
            Action: 'sts:AssumeRole'
      Policies:
        - PolicyName: ${var.name}
          PolicyDocument:
            Version: "2012-10-17"
            Statement:
              - Effect: Allow
                Action: 'events:PutEvents'
                Resource: ${var.target_event_bus_arn}
  EventBridgeRule:
    Type: AWS::Events::Rule
    Properties:
      Name: ${var.name}
      Description: Capture all CloudTrail events
      EventPattern:
        detail-type:
          - 'AWS API Call via CloudTrail'
      Targets:
        - Id: ${var.name}
          Arn: ${var.target_event_bus_arn}
          RoleArn: !GetAtt
            - EventBridgeRole
            - Arn
%{if var.target_dead_letter_queue_arn != ""}
          DeadLetterConfig:
            Arn: ${var.target_dead_letter_queue_arn}
%{endif}
TEMPLATE
}

resource "aws_cloudformation_stack_set_instance" "stackset_instance" {
  count = var.is_organizational ? 1 : 0

  stack_set_name = aws_cloudformation_stack_set.stackset[0].name
  deployment_targets {
    organizational_unit_ids = local.organizational_unit_ids
  }
}
