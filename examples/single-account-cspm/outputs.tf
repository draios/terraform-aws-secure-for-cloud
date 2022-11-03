output "cspm_role_arn" {
  //  value       = length(module.cloudtrail) > 0 ? module.cloudtrail[0].cloudtrail_sns_arn : var.cloudtrail_sns_arn
  value       = module.cspm_single.cspm_role_arn
  description = "ARN of cspm role"
}
