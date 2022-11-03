output "cspm_role_arn" {
  value       = aws_iam_role.cspm_role[0].arn
  description = "ARN of cspm role"
}