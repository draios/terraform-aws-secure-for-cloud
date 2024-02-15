output "role_arn" {
  description = "Role used by Sysdig Platform for Agentless Workload Scanning"
  value       = var.is_organizational ? null : var.deploy_global_resources ? aws_iam_role.scanning[0].arn : var.role_arn
}
