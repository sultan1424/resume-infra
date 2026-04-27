# S3 bucket for storing uploaded CV files
resource "aws_s3_bucket" "cv_storage" {
  bucket = "${var.project_name}-cv-storage-${var.environment}"

  tags = {
    Name        = "${var.project_name}-cv-storage"
    Environment = var.environment
  }
}

# Block all public access — CVs are private
resource "aws_s3_bucket_public_access_block" "cv_storage" {
  bucket = aws_s3_bucket.cv_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Enable versioning — keeps history of uploaded files
resource "aws_s3_bucket_versioning" "cv_storage" {
  bucket = aws_s3_bucket.cv_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}
