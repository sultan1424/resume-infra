# ─────────────────────────────────────────
# Frontend S3 bucket — static website hosting
# ─────────────────────────────────────────
resource "aws_s3_bucket" "frontend" {
  bucket = "${var.project_name}-frontend-${var.environment}"

  tags = {
    Name        = "${var.project_name}-frontend"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_website_configuration" "frontend" {
  bucket = aws_s3_bucket.frontend.id

  index_document { suffix = "index.html" }
  error_document { key    = "index.html" }
}

resource "aws_s3_bucket_policy" "frontend" {
  bucket     = aws_s3_bucket.frontend.id
  depends_on = [aws_s3_bucket_public_access_block.frontend]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.frontend.arn}/*"
    }]
  })
}

# ─────────────────────────────────────────
# S3 bucket for storing uploaded CV files
# ─────────────────────────────────────────
resource "aws_s3_bucket" "cv_storage" {
  bucket = "${var.project_name}-cv-storage-${var.environment}"

  tags = {
    Name        = "${var.project_name}-cv-storage"
    Environment = var.environment
  }
}

resource "aws_s3_bucket_public_access_block" "cv_storage" {
  bucket = aws_s3_bucket.cv_storage.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_s3_bucket_versioning" "cv_storage" {
  bucket = aws_s3_bucket.cv_storage.id

  versioning_configuration {
    status = "Enabled"
  }
}
