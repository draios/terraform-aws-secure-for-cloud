output "cloudtrail_sns_topic_arn" {
  //  value       = length(module.cloudtrail) > 0 ? module.cloudtrail[0].cloudtrail_sns_arn : var.cloudtrail_sns_arn
  value       = length(module.cspm_single)
  description = "ARN of cloudtrail_sns topic"
}
