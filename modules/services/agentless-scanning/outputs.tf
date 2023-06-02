output "agentless_role_arn" {
  description = "Role used by Sysdig BE for Secure Agentless"
  value       = aws_iam_role.agentless.arn
}

output "kms_key" {
  description = "Multi-region KMS key ID and ARN"
  value = {
    id  = aws_kms_key.agentless.key_id
    arn = aws_kms_key.agentless.arn
  }
}

output "kms_key_alias" {
  description = "Multi-region KMS key alias"
  value       = aws_kms_alias.agentless
}
