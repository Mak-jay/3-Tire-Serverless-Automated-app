# ---------------------------------------------------------------------------
# Remote state backend. CI runs (GitHub Actions) start with a clean runner
# every time, so local state is not an option here — state must live
# somewhere persistent and shared. This bucket/table pair is that home.
#
# NOTE: this is a bootstrapping chicken-and-egg problem — these two
# resources must exist and this bootstrap config itself should keep using
# local state (or its own separate remote state) rather than pointing at
# the bucket it's creating. Do NOT add a `backend "s3"` block to *this*
# bootstrap/ directory referencing this bucket. Configure the backend in
# your APPLICATION Terraform (the 3-tier app repo/dir) instead, using the
# outputs below.
# ---------------------------------------------------------------------------

resource "aws_s3_bucket" "terraform_state" {
  bucket = "${var.app_name}-terraform-state-${data.aws_caller_identity.current.account_id}"
  tags   = var.tags
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id
  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket                  = aws_s3_bucket.terraform_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "${var.app_name}-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = var.tags
}
