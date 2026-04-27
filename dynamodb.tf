# DynamoDB table for storing CV analysis results
resource "aws_dynamodb_table" "results" {
  name         = "${var.project_name}-results-${var.environment}"
  billing_mode = "PAY_PER_REQUEST"  # No capacity planning needed — scales automatically
  hash_key     = "cv_id"

  attribute {
    name = "cv_id"
    type = "S"  # String
  }

  tags = {
    Name        = "${var.project_name}-results"
    Environment = var.environment
  }
}
