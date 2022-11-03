output "cspm_role_arn" {
  //  value       = length(module.cloudtrail) > 0 ? module.cloudtrail[0].cloudtrail_sns_arn : var.cloudtrail_sns_arn
  value       = aws_iam_role.cspm_role[0].name
  description = "ARN of cspm role"
}