#-----------------------------------------------------------------------------------------------------------------------
# We have two types of resources. global and regional. Global resources are deployed only once.
# we use deploy_global_resources boolean to determine that.
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# These locals indicate if global resources are already created or not. If they are created
# their details are passed and used.
#-----------------------------------------------------------------------------------------------------------------------

# Rule to capture all events from CloudTrail in the source account.
locals {
  is_role_empty = length(var.role_arn) == 0
}
#-----------------------------------------------------------------------------------------------------------------------
# Determine if this is an Organizational install, or a single account install. For Single Account installs, resources
# are created directly using the AWS Terraform Provider (This is the default behaviour). For Organizational installs,
# a CloudFormation StackSet is used (See organizational.tf), and the resources in this file are used to instrument the
# management account (StackSets do not include the management account they are create in, even if this account is within
# the target Organization).
#-----------------------------------------------------------------------------------------------------------------------

#-----------------------------------------------------------------------------------------------------------------------
# These resources set up an EventBridge Rule and Target to forward all CloudTrail events from the source account to
# Sysdig. CloudTrail events are sent to the default EventBridge Bus in the source account automatically.
#-----------------------------------------------------------------------------------------------------------------------

# Rule to capture all events from CloudTrail in the source account.

resource "aws_cloudwatch_event_rule" "sysdig" {
  count       = var.is_organizational ? 0 : 1
  name        = var.name
  description = "Capture all CloudTrail events"
  tags        = var.tags
  state       = var.rule_state

  event_pattern = var.event_pattern
}
# Target to forward all CloudTrail events to Sysdig's EventBridge Bus.
# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target#cross-account-event-bus-target
resource "aws_cloudwatch_event_target" "sysdig" {
  count      = var.is_organizational ? 0 : 1
  depends_on = [aws_iam_role.event_bus_invoke_remote_event_bus, aws_cloudwatch_event_rule.sysdig]

  rule     = aws_cloudwatch_event_rule.sysdig[0].name
  arn      = var.target_event_bus_arn
  role_arn = local.is_role_empty ? aws_iam_role.event_bus_invoke_remote_event_bus[0].arn : var.role_arn

}

#-----------------------------------------------------------------------------------------------------------------------
# These resources create an IAM role in the source account with permissions to call PutEvent on the EventBridge Bus in
# Sysdig's AWS account. This role is attached to the EventBridge target that is created in the source account.
#-----------------------------------------------------------------------------------------------------------------------

# Role that will be used by EventBridge when sending events to Sysdig's EventBridge Bus. The EventBridge service is
# given permission to assume this role.
resource "aws_iam_role" "event_bus_invoke_remote_event_bus" {
  count = (var.is_organizational && var.mgt_stackset || var.deploy_global_resources) ? 1 : 0

  name = var.name
  tags = var.tags

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "events.amazonaws.com"
      },
      "Effect": "Allow"
    },
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "AWS": "${var.trusted_identity}"
      },
      "Effect": "Allow",
      "Condition": {
        "StringEquals": {
          "sts:ExternalId": "${var.external_id}"
        }
      }
    }
  ]
}
EOF
  inline_policy {
    name   = var.name
    policy = data.aws_iam_policy_document.cloud_trail_events.json
  }
}

# IAM Policy Document used by EventBridge role for the cloudtrail events policy
data "aws_iam_policy_document" "cloud_trail_events" {

  statement {
    sid = "CloudTrailEventsPut"

    effect = "Allow"

    actions = [
      "events:PutEvents",
    ]

    resources = [
      var.target_event_bus_arn,
    ]
  }

  statement {
    sid = "CloudTrailEventRuleAccess"

    effect = "Allow"

    actions = [
      "events:DescribeRule",
      "events:ListTargetsByRule",
    ]

    resources = [
      "arn:aws:events:*:*:rule/${var.name}",
    ]
  }
}
