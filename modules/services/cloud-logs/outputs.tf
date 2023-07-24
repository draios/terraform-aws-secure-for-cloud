output "role_arn" {
  value       = aws_iam_role.cloudlogs_s3_access.arn
  description = "ARN of CloudLogs role"
}
