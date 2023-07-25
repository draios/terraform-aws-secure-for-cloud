output "role_arn" {
  description = "Role used by Sysdig Platform for Secure Agentless Scanning"
  value       = var.is_organizational ? null : var.deploy_global_resources ? aws_iam_role.agentless[0].arn : var.role_arn
}

output "kms_key" {
  description = "KMS key ID and ARN"
  value = var.is_organizational ? null : {
    id  = aws_kms_key.agentless[0].key_id
    arn = aws_kms_key.agentless[0].arn
  }
}

output "kms_key_alias" {
  description = "KMS key alias"
  value       = var.is_organizational ? null : aws_kms_alias.agentless
}
