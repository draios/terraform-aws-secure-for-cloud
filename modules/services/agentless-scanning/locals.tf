data "aws_caller_identity" "current" {}
data "aws_iam_session_context" "current" {
  // Get the source role ARN from the currently assumed session role
  arn = data.aws_caller_identity.current.arn
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  caller_arn = data.aws_iam_session_context.current.issuer_arn
}

#-----------------------------------------------------------------------------------------------------------------------
# Dertermine whether to deploy self-managed stacksets in the management account.
# This might be disabled if using a delegated admin account or to avoid creating a stackset admin and execution role
# in the management account.
#-----------------------------------------------------------------------------------------------------------------------
locals {
  deploy_stackset = var.mgt_stackset && !var.delegated_admin
}