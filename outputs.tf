output "api_gateway_url" {
  description = "Base URL of the API Gateway"
  value       = aws_apigatewayv2_api.main.api_endpoint
}

output "s3_bucket_name" {
  description = "Name of the S3 bucket storing uploaded CVs"
  value       = aws_s3_bucket.cv_storage.bucket
}

output "dynamodb_table_name" {
  description = "Name of the DynamoDB table storing analysis results"
  value       = aws_dynamodb_table.results.name
}

output "ecr_upload_service_url" {
  description = "ECR repository URL for the Upload Service image"
  value       = aws_ecr_repository.upload_service.repository_url
}

output "ecr_ai_service_url" {
  description = "ECR repository URL for the AI Analysis Service image"
  value       = aws_ecr_repository.ai_service.repository_url
}

output "frontend_url" {
  description = "Frontend website URL"
  value       = "http://${aws_s3_bucket_website_configuration.frontend.website_endpoint}"
}

output "alb_url" {
  description = "Direct ALB URL for testing"
  value       = "http://${aws_lb.main.dns_name}"
}
