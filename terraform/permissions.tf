# ---------------------------------------------------------------------------
# Deploy permissions for the github-actions-deployer role, scoped to
# resources prefixed with var.app_name ("3tier-*" by default) wherever the
# service supports resource-level ARN scoping. A few services (API Gateway
# REST APIs, and IAM's list/read actions) don't support fine-grained
# resource ARNs for the actions Terraform needs, so those are broader by
# necessity -- noted inline below.
# ---------------------------------------------------------------------------

data "aws_iam_policy_document" "deployer_permissions" {

  # --- Terraform state backend access -------------------------------------
  statement {
    sid    = "TerraformStateBucket"
    effect = "Allow"
    actions = [
      "s3:ListBucket",
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject",
    ]
    resources = [
      aws_s3_bucket.terraform_state.arn,
      "${aws_s3_bucket.terraform_state.arn}/*",
    ]
  }

  statement {
    sid       = "TerraformStateLock"
    effect    = "Allow"
    actions   = ["dynamodb:GetItem", "dynamodb:PutItem", "dynamodb:DeleteItem"]
    resources = [aws_dynamodb_table.terraform_locks.arn]
  }

  # --- App S3 buckets (static assets / app data, NOT the state bucket) ----
  statement {
    sid    = "AppS3"
    effect = "Allow"
    actions = [
      "s3:CreateBucket", "s3:DeleteBucket", "s3:ListBucket",
      "s3:GetObject", "s3:PutObject", "s3:DeleteObject",
      "s3:GetBucketPolicy", "s3:PutBucketPolicy", "s3:DeleteBucketPolicy",
      "s3:GetBucketVersioning", "s3:PutBucketVersioning",
      "s3:GetEncryptionConfiguration", "s3:PutEncryptionConfiguration",
      "s3:GetBucketPublicAccessBlock", "s3:PutBucketPublicAccessBlock",
      "s3:GetBucketWebsite", "s3:PutBucketWebsite", "s3:DeleteBucketWebsite",
      "s3:GetBucketCORS", "s3:PutBucketCORS",
      "s3:GetBucketTagging", "s3:PutBucketTagging",
    ]
    resources = [
      "arn:aws:s3:::${var.app_name}-*",
      "arn:aws:s3:::${var.app_name}-*/*",
    ]
  }

  # --- DynamoDB app tables --------------------------------------------------
  statement {
    sid    = "AppDynamoDB"
    effect = "Allow"
    actions = [
      "dynamodb:CreateTable", "dynamodb:DeleteTable", "dynamodb:DescribeTable",
      "dynamodb:UpdateTable", "dynamodb:ListTagsOfResource", "dynamodb:TagResource",
      "dynamodb:UntagResource", "dynamodb:DescribeTimeToLive", "dynamodb:UpdateTimeToLive",
      "dynamodb:DescribeContinuousBackups", "dynamodb:UpdateContinuousBackups",
    ]
    resources = [
      "arn:aws:dynamodb:*:${data.aws_caller_identity.current.account_id}:table/${var.app_name}-*",
    ]
  }

  # --- Lambda ---------------------------------------------------------------
  statement {
    sid    = "AppLambda"
    effect = "Allow"
    actions = [
      "lambda:CreateFunction", "lambda:DeleteFunction", "lambda:GetFunction",
      "lambda:UpdateFunctionCode", "lambda:UpdateFunctionConfiguration",
      "lambda:GetFunctionConfiguration", "lambda:ListVersionsByFunction",
      "lambda:PublishVersion", "lambda:CreateAlias", "lambda:UpdateAlias",
      "lambda:DeleteAlias", "lambda:GetAlias", "lambda:AddPermission",
      "lambda:RemovePermission", "lambda:GetPolicy", "lambda:TagResource",
      "lambda:UntagResource", "lambda:ListTags",
    ]
    resources = [
      "arn:aws:lambda:*:${data.aws_caller_identity.current.account_id}:function:${var.app_name}-*",
    ]
  }

  # --- API Gateway ------------------------------------------------------------
  # API Gateway (REST/HTTP) does not support resource-level ARN scoping for
  # the create/manage actions Terraform needs -- AWS's own managed policies
  # for API Gateway admin access use "*" for this reason. This is a known,
  # accepted broadness for this service; Terraform will still only touch
  # what's declared in your config.
  statement {
    sid       = "AppApiGateway"
    effect    = "Allow"
    actions   = ["apigateway:*"]
    resources = ["arn:aws:apigateway:*::/restapis*"]
  }

  # --- CloudFront -------------------------------------------------------------
  statement {
    sid    = "AppCloudFront"
    effect = "Allow"
    actions = [
      "cloudfront:CreateDistribution", "cloudfront:DeleteDistribution",
      "cloudfront:GetDistribution", "cloudfront:UpdateDistribution",
      "cloudfront:ListDistributions", "cloudfront:TagResource",
      "cloudfront:UntagResource", "cloudfront:CreateOriginAccessControl",
      "cloudfront:GetOriginAccessControl", "cloudfront:DeleteOriginAccessControl",
      "cloudfront:CreateInvalidation", "cloudfront:GetInvalidation",
    ]
    resources = ["*"] # CloudFront distribution IDs are only known after creation; no ARN scoping available pre-create
  }

  # --- CloudWatch Logs (Lambda automatically creates log groups) ----------
  statement {
    sid    = "AppLogs"
    effect = "Allow"
    actions = [
      "logs:CreateLogGroup", "logs:DeleteLogGroup", "logs:DescribeLogGroups",
      "logs:PutRetentionPolicy", "logs:TagLogGroup", "logs:TagResource",
    ]
    resources = [
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.app_name}-*",
      "arn:aws:logs:*:${data.aws_caller_identity.current.account_id}:log-group:/aws/lambda/${var.app_name}-*:*",
    ]
  }

  # --- IAM: Lambda execution roles only, tightly scoped --------------------
  # This is the one place a wildcard-like grant is genuinely risky (privilege
  # escalation via role creation), so it's scoped as tightly as IAM allows:
  # role NAME prefix restricts CreateRole/DeleteRole/etc, and PassRole is
  # restricted to the same prefix -- Terraform can create Lambda exec roles
  # and pass them to Lambda, but cannot create or pass any role outside
  # this app's naming convention.
  statement {
    sid    = "AppIAMRoles"
    effect = "Allow"
    actions = [
      "iam:CreateRole", "iam:DeleteRole", "iam:GetRole",
      "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:GetRolePolicy",
      "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies", "iam:TagRole", "iam:UntagRole",
    ]
    resources = [
      "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app_name}-*",
    ]
  }

  statement {
    sid       = "AppIAMPassRole"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = ["arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${var.app_name}-*"]
    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["lambda.amazonaws.com"]
    }
  }
}

resource "aws_iam_policy" "deployer_permissions" {
  name        = "${var.role_name}-permissions"
  description = "Scoped deploy permissions for the ${var.app_name} 3-tier app pipeline"
  policy      = data.aws_iam_policy_document.deployer_permissions.json
}

resource "aws_iam_role_policy_attachment" "deployer_permissions" {
  role       = aws_iam_role.deployer.name
  policy_arn = aws_iam_policy.deployer_permissions.arn
}
