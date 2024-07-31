output "role_arn" {
  value = local.is_role_empty && local.deploy_stackset ? aws_iam_role.event_bus_invoke_remote_event_bus[0].arn : ""

  description = "ARN of cspm role"
}
