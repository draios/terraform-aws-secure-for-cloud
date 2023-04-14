output "cspm_role_arn" {
  value       = aws_iam_role.cspm_role.arn
  description = "ARN of cspm role"
}
