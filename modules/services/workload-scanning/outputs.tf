output "role_arn" {
  description = "Role used by Sysdig Platform for Agentless Workload Scanning"
  value       = var.is_organizational ? null : var.deploy_global_resources ? aws_iam_role.scanning[0].arn : var.role_arn
}

output "validate_deploy_global_resources" {
  value = null
  precondition {
    condition     = (var.deploy_global_resources && var.external_id != null)
    error_message = "Please provide external_id or set deploy_global_resources to false."
  }
  precondition {
    condition     = (var.deploy_global_resources && var.role_arn != null)
    error_message = "Please provide ecr_role_name or set deploy_global_resources set to false."
  }
  precondition {
    condition     = (var.deploy_global_resources && var.trusted_identity != null)
    error_message = "Please provide trusted_identity or set deploy_global_resources to false."
  }
}
