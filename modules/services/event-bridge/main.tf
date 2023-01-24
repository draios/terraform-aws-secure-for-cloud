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
  count = var.is_organizational && !var.provision_management_account ? 0 : 1

  name        = var.name
  description = "Capture all CloudTrail events"
  tags        = var.tags

  event_pattern = <<EOF
{
  "detail-type": [
    "AWS API Call via CloudTrail"
  ]
}
EOF
}

# Target to forward all CloudTrail events to Sysdig's EventBridge Bus.
# See https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target#cross-account-event-bus-target
resource "aws_cloudwatch_event_target" "sysdig" {
  count = var.is_organizational && !var.provision_management_account ? 0 : 1

  rule     = aws_cloudwatch_event_rule.sysdig[0].name
  arn      = var.target_event_bus_arn
  role_arn = aws_iam_role.event_bus_invoke_remote_event_bus[0].arn

  dead_letter_config {
    arn = var.target_dead_letter_queue_arn
  }
}

#-----------------------------------------------------------------------------------------------------------------------
# These resources create an IAM role in the source account with permissions to call PutEvent on the EventBridge Bus in
# Sysdig's AWS account. This role is attached to the EventBridge target that is created in the source account.
#-----------------------------------------------------------------------------------------------------------------------

# Role that will be used by EventBridge when sending events to Sysdig's EventBridge Bus. The EventBridge service is
# given permission to assume this role.
resource "aws_iam_role" "event_bus_invoke_remote_event_bus" {
  count = var.is_organizational && !var.provision_management_account ? 0 : 1

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
    }
  ]
}
EOF
}

# Policy document that allows PutEvents on the target EventBridge Bus in Sysdig's account.
data "aws_iam_policy_document" "event_bus_invoke_remote_event_bus" {
  count = var.is_organizational && !var.provision_management_account ? 0 : 1

  statement {
    effect    = "Allow"
    actions   = ["events:PutEvents"]
    resources = [var.target_event_bus_arn]
  }
}

# Policy allowing PutEvents on the target EventBridge Bus in Sysdig's account which will be attached to the role used
# by EventBridge in the source account.
resource "aws_iam_policy" "event_bus_invoke_remote_event_bus" {
  count = var.is_organizational && !var.provision_management_account ? 0 : 1

  name   = var.name
  tags   = var.tags
  policy = data.aws_iam_policy_document.event_bus_invoke_remote_event_bus[0].json
}

# Policy Attachment connecting the role & policy
resource "aws_iam_role_policy_attachment" "event_bus_invoke_remote_event_bus" {
  count = var.is_organizational && !var.provision_management_account ? 0 : 1

  role       = aws_iam_role.event_bus_invoke_remote_event_bus[0].name
  policy_arn = aws_iam_policy.event_bus_invoke_remote_event_bus[0].arn
}
