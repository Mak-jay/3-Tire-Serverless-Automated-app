# output "cloudfront_domain_name" {
#   description = "CloudFront URL for the frontend (upload your built site to the frontend bucket, then visit this)"
#   value       = aws_cloudfront_distribution.frontend.domain_name
# }

output "api_invoke_url" {
  description = "Base URL for the API — try GET <this>/items or POST with a JSON body"
  value       = aws_api_gateway_stage.this.invoke_url
}

output "frontend_bucket_name" {
  description = "S3 bucket to upload built frontend assets to"
  value       = aws_s3_bucket.frontend.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.app_data.name
}

output "lambda_function_name" {
  value = aws_lambda_function.api.function_name
}
