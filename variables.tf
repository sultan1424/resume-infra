variable "aws_region" {
  description = "AWS region to deploy all resources"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used as prefix for all resources"
  type        = string
  default     = "resume-analyzer"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "upload_service_image" {
  description = "Docker image URI for the Upload Service (from ECR)"
  type        = string
}

variable "ai_service_image" {
  description = "Docker image URI for the AI Analysis Service (from ECR)"
  type        = string
}
