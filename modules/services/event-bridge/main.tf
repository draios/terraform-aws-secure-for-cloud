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
  is_role_empty       = length(var.role_arn) == 0
  is_policy_empty     = length(var.policy_arn) == 0
  is_policy_doc_empty = length(var.policy_document_json) == 0
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
  name        = var.name
  description = "Capture all CloudTrail events"
  tags        = var.tags

  event_pattern = <<EOF
{
  "detail-type": [
    "AWS API Call via CloudTrail",
    "AWS Console Sign In via CloudTrail",
    "AWS Service Event via CloudTrail"
  ]
}
EOF
}

# Target to forward all CloudTrail events to Sysdig's EventBridge Bus.
# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target#cross-account-event-bus-target
resource "aws_cloudwatch_event_target" "sysdig" {
  depends_on = [aws_iam_role.event_bus_invoke_remote_event_bus]

  //  rule     = aws_cloudwatch_event_rule.sysdig[0].name
  rule     = aws_cloudwatch_event_rule.sysdig.name
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
  count = (var.is_organizational || var.deploy_global_resources) ? 1 : 0

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
}

# Policy document that allows PutEvents on the target EventBridge Bus in Sysdig's account.
data "aws_iam_policy_document" "event_bus_invoke_remote_event_bus" {
  count = (var.is_organizational || var.deploy_global_resources) ? 1 : 0

  statement {
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [var.target_event_bus_arn]
  }
}

# Policy allowing PutEvents on the target EventBridge Bus in Sysdig's account which will be attached to the role used
# by EventBridge in the source account.
resource "aws_iam_policy" "event_bus_invoke_remote_event_bus" {
  count      = (var.is_organizational || var.deploy_global_resources) ? 1 : 0
  depends_on = [aws_iam_role.event_bus_invoke_remote_event_bus, data.aws_iam_policy_document.event_bus_invoke_remote_event_bus]

  name   = var.name
  tags   = var.tags
  policy = local.is_policy_doc_empty ? data.aws_iam_policy_document.event_bus_invoke_remote_event_bus[0].json : var.policy_document_json
}

# Policy Attachment connecting the role & policy
resource "aws_iam_role_policy_attachment" "event_bus_invoke_remote_event_bus" {
  count      = (var.is_organizational || var.deploy_global_resources) ? 1 : 0
  depends_on = [aws_iam_role.event_bus_invoke_remote_event_bus, aws_iam_policy.event_bus_invoke_remote_event_bus]


  role       = local.is_role_empty ? aws_iam_role.event_bus_invoke_remote_event_bus[0].name : var.role_arn
  policy_arn = local.is_policy_empty ? aws_iam_policy.event_bus_invoke_remote_event_bus[0].arn : var.policy_arn
}
