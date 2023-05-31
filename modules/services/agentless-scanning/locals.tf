data "aws_caller_identity" "current" {}

locals {
  account_id           = data.aws_caller_identity.current.account_id
  caller_arn           = data.aws_caller_identity.current.arn
  agentless_account_id = "315105463264"
}
