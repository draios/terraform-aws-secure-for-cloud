output "cspm_role_arn" {
  //  value       = length(module.cloudtrail) > 0 ? module.cloudtrail[0].cloudtrail_sns_arn : var.cloudtrail_sns_arn
  value       = var.role_name
  description = "ARN of cspm role"
}
