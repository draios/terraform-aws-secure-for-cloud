output "role_arn" {
  value       = local.is_role_empty && var.mgt_stackset && !var.delegated ? aws_iam_role.event_bus_invoke_remote_event_bus[0].arn : ""
  description = "ARN of cspm role"
}
