data "aws_caller_identity" "current" {}

# Fetch GitHub's current TLS certificate chain and use the ROOT CA entry
# (last in the chain) for the thumbprint. The root barely ever rotates,
# unlike the leaf cert, so this stays valid far longer if hand-copied
# thumbprints go stale. AWS requires the field to be present but no longer
# strictly validates it against GitHub's actual chain.

data "tls_certificate" "github" {
  url = "https://token.actions.githubusercontent.com/.well-known/openid-configuration"
}

resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"

  client_id_list = [
    "sts.amazonaws.com",
  ]

  thumbprint_list = [
    data.tls_certificate.github.certificates[length(data.tls_certificate.github.certificates) - 1].sha1_fingerprint,
  ]

  tags = var.tags
}

# ---------------------------------------------------------------------------
# Trust policy: only workflows running from the specified repo + branches
# (and optionally pull_request events) may assume this role.
# ---------------------------------------------------------------------------
locals {
  repo_prefix = "repo:${var.github_org}@${var.github_owner_id}/${var.github_repo}@${var.github_repo_id}"

  branch_subs = [
    for b in var.allowed_branches : "${local.repo_prefix}:ref:refs/heads/${b}"
  ]
  pr_subs = var.allow_pull_requests ? [
    "${local.repo_prefix}:pull_request"
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

# ---------------------------------------------------------------------------
# NOTE: no permissions policy is attached here on purpose. Attach a scoped
# policy (or AdministratorAccess temporarily, for bootstrap only) once the
# pipeline's actual needs are known — that's a later phase.
# ---------------------------------------------------------------------------
