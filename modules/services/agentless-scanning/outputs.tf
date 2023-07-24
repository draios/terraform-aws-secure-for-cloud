output "agentless_role_arn" {
  description = "Role used by Sysdig BE for Secure Agentless"
  value       = var.deploy_global_resources ? aws_iam_role.agentless[0].arn : ""
}

output "kms_key" {
  description = "KMS key ID and ARN"
  value = {
    id  = var.is_organizational ? "" : aws_kms_key.agentless[0].key_id
    arn = var.is_organizational ? "" : aws_kms_key.agentless[0].arn
  }
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = aws_kms_alias.agentless
}
