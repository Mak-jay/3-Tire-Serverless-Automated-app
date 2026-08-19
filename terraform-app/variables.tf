variable "aws_region" {
  description = "AWS region for all app resources"
  type        = string
  default     = "us-east-1"
}

variable "app_name" {
  description = "Prefix for every resource this config creates. MUST match the prefix the deployer IAM policy is scoped to (see bootstrap/permissions.tf) or every apply will fail with AccessDenied."
  type        = string
  default     = "3tier"
}

variable "environment" {
  description = "Deployment stage name (used as the API Gateway stage)"
  type        = string
  default     = "prod"
}
