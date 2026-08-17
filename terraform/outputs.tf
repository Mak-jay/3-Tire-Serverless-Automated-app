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

output "terraform_state_bucket" {
  description = "S3 bucket name to use as the 'bucket' in your app's backend \"s3\" block"
  value       = aws_s3_bucket.terraform_state.id
}

output "terraform_lock_table" {
  description = "DynamoDB table name to use as the 'dynamodb_table' in your app's backend \"s3\" block"
  value       = aws_dynamodb_table.terraform_locks.name
}
