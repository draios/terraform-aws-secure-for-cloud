output "role_arn" {
  value       = local.is_role_empty ? aws_iam_role.event_bus_invoke_remote_event_bus[0].arn : ""
  description = "ARN of cspm role"
}

output "policy_arn" {
  value       = local.is_policy_empty ? aws_iam_policy.event_bus_invoke_remote_event_bus[0].arn : ""
  description = "ARN of cspm role"
}

output "policy_document_json" {
  value       = local.is_policy_doc_empty ? data.aws_iam_policy_document.event_bus_invoke_remote_event_bus[0].json : ""
  description = "ARN of cspm role"
}