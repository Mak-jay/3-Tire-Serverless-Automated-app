output "oidc_provider_arn" {
  description = "ARN of the GitHub OIDC provider"
  value       = aws_iam_openid_connect_provider.github.arn
}

output "deployer_role_arn" {
  description = "ARN of the IAM role GitHub Actions workflows should assume"
  value       = aws_iam_role.deployer.arn
}

output "deployer_role_name" {
  description = "Name of the IAM deployer role"
  value       = aws_iam_role.deployer.name
}
