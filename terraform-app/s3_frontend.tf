resource "aws_s3_bucket" "frontend" {
  bucket = "${var.app_name}-frontend-${data.aws_caller_identity.current.account_id}"
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket                  = aws_s3_bucket.frontend.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Bucket stays fully private — CloudFront reaches it via Origin Access
# Control (OAC), the current recommended approach (OAI is legacy).
#
# COMMENTED OUT: depends on aws_cloudfront_distribution.frontend, which is
# disabled until the AWS account CloudFront verification clears. Bucket
# stays private with no read access at all in the meantime — that's fine,
# nothing needs to reach it yet. Uncomment this whole block once
# cloudfront.tf is restored.
#
# data "aws_iam_policy_document" "frontend_bucket_policy" {
#   statement {
#     sid    = "AllowCloudFrontOAC"
#     effect = "Allow"
#
#     principals {
#       type        = "Service"
#       identifiers = ["cloudfront.amazonaws.com"]
#     }
#
#     actions   = ["s3:GetObject"]
#     resources = ["${aws_s3_bucket.frontend.arn}/*"]
#
#     condition {
#       test     = "StringEquals"
#       variable = "AWS:SourceArn"
#       values   = [aws_cloudfront_distribution.frontend.arn]
#     }
#   }
# }
#
# resource "aws_s3_bucket_policy" "frontend" {
#   bucket = aws_s3_bucket.frontend.id
#   policy = data.aws_iam_policy_document.frontend_bucket_policy.json
# }
