output "cloudtrail_sns_topic_arn" {
  value       = length(module.cloudtrail) > 0 ? module.cloudtrail[0].cloudtrail_sns_arn : var.existing_cloudtrail_config.cloudtrail_sns_arn
  description = "ARN of cloudtrail_sns topic"
}

output "role_arn" {
  value       = module.cspm_org.cspm_role_arn
  description = "ARN of cspm role"
}