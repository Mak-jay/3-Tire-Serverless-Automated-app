variable "aws_region" {
  description = "AWS region to deploy the bootstrap resources into"
  type        = string
  default     = "us-east-1"
}

variable "github_org" {
  description = "GitHub organization (or user) that owns the repo"
  type        = string
}

variable "github_repo" {
  description = "GitHub repository name (without org prefix)"
  type        = string
}

variable "allowed_branches" {
  description = "Branches allowed to assume the deployer role via OIDC (used in the sub claim condition)"
  type        = list(string)
  default     = ["main"]
}

variable "allow_pull_requests" {
  description = "If true, also trust the pull_request event subject (repo:ORG/REPO:pull_request), useful for plan-only workflows on PRs"
  type        = bool
  default     = false
}

variable "role_name" {
  description = "Name of the IAM role GitHub Actions will assume"
  type        = string
  default     = "github-actions-deployer"
}

variable "max_session_duration" {
  description = "Max session duration (seconds) for the deployer role"
  type        = number
  default     = 3600
}

variable "tags" {
  description = "Tags applied to created resources"
  type        = map(string)
  default = {
    ManagedBy = "terraform"
    Purpose   = "github-oidc-bootstrap"
  }
}
