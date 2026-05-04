# ECR repository for the Upload Service
resource "aws_ecr_repository" "upload_service" {
  name                 = "${var.project_name}-upload-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-upload-service"
    Environment = var.environment
  }
}

# ECR repository for the AI Analysis Service
resource "aws_ecr_repository" "ai_service" {
  name                 = "${var.project_name}-ai-service"
  image_tag_mutability = "MUTABLE"
  force_delete         = true

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.project_name}-ai-service"
    Environment = var.environment
  }
}
