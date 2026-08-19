resource "aws_dynamodb_table" "app_data" {
  name         = "${var.app_name}-items"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "id"

  attribute {
    name = "id"
    type = "S"
  }

  tags = {
    ManagedBy = "terraform"
    App       = var.app_name
  }
}
