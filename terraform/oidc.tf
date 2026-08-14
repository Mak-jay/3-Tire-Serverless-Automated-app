data "aws_caller_identity" "current" {}

# GitHub's OIDC provider. AWS validates the token against GitHub's TLS chain;
# the thumbprint below is GitHub's current intermediate CA root thumbprint,
# required by the API but no longer actually used for verification.
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea",
  ]

  tags = var.tags
}

# Trust policy: only workflows running from the specified repo + branches
# (and optionally pull_request events) may assume this role.
locals {
  branch_subs = [
    for b in var.allowed_branches : "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${b}"
  ]
  pr_subs = var.allow_pull_requests ? [
    "repo:${var.github_org}/${var.github_repo}:pull_request"
  ] : []
  allowed_subs = concat(local.branch_subs, local.pr_subs)
}

data "aws_iam_policy_document" "deployer_trust" {
  statement {
    sid     = "GitHubActionsOIDC"
    effect  = "Allow"
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = local.allowed_subs
    }
  }
}

resource "aws_iam_role" "deployer" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.deployer_trust.json
  max_session_duration = var.max_session_duration
  tags                 = var.tags
}
# NOTE: no permissions policy is attached here on purpose. Attach a scoped
# policy (or AdministratorAccess temporarily, for bootstrap only) once the
# pipeline's actual needs are known 
