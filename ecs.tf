# ─────────────────────────────────────────
# ECS Cluster — shared by both services
# ─────────────────────────────────────────
resource "aws_ecs_cluster" "main" {
  name = "${var.project_name}-cluster"

  tags = {
    Name        = "${var.project_name}-cluster"
    Environment = var.environment
  }
}

# CloudWatch log groups — Factor 11 (Logs go to stdout → CloudWatch)
resource "aws_cloudwatch_log_group" "upload_service" {
  name              = "/ecs/${var.project_name}/upload-service"
  retention_in_days = 7
}

resource "aws_cloudwatch_log_group" "ai_service" {
  name              = "/ecs/${var.project_name}/ai-service"
  retention_in_days = 7
}

# ─────────────────────────────────────────
# Upload Service — Task Definition
# ─────────────────────────────────────────
resource "aws_ecs_task_definition" "upload_service" {
  family                   = "${var.project_name}-upload-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 512
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "upload-service"
    image = var.upload_service_image

    portMappings = [{
      containerPort = 8080
      protocol      = "tcp"
    }]

    # Factor 3 — configuration via environment variables, not hardcoded
    environment = [
      { name = "S3_BUCKET_NAME",     value = aws_s3_bucket.cv_storage.bucket },
      { name = "AI_SERVICE_URL",     value = "http://${aws_lb.main.dns_name}" },
      { name = "DYNAMODB_TABLE",     value = aws_dynamodb_table.results.name },
      { name = "AWS_REGION",         value = var.aws_region },
      { name = "PORT",               value = "8080" }
    ]

    # Factor 11 — logs go to stdout → CloudWatch
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.upload_service.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Name        = "${var.project_name}-upload-service"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────
# AI Analysis Service — Task Definition
# ─────────────────────────────────────────
resource "aws_ecs_task_definition" "ai_service" {
  family                   = "${var.project_name}-ai-service"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = 512   # More CPU for AI processing
  memory                   = 1024  # More memory for RAG pipeline
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  task_role_arn            = aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([{
    name  = "ai-service"
    image = var.ai_service_image

    portMappings = [{
      containerPort = 8081
      protocol      = "tcp"
    }]

    # Factor 3 — configuration via environment variables
    environment = [
      { name = "S3_BUCKET_NAME",        value = aws_s3_bucket.cv_storage.bucket },
      { name = "DYNAMODB_TABLE",        value = aws_dynamodb_table.results.name },
      { name = "OPENSEARCH_ENDPOINT",   value = "https://${aws_opensearch_domain.vector_store.endpoint}" },
      { name = "BEDROCK_REGION",        value = var.aws_region },
      { name = "BEDROCK_MODEL_ID",      value = "amazon.nova-lite-v1:0" },
      { name = "BEDROCK_EMBED_MODEL_ID",value = "amazon.titan-embed-text-v2:0" },
      { name = "AWS_REGION",            value = var.aws_region },
      { name = "PORT",                  value = "8081" }
    ]

    # Factor 11 — logs go to stdout → CloudWatch
    logConfiguration = {
      logDriver = "awslogs"
      options = {
        awslogs-group         = aws_cloudwatch_log_group.ai_service.name
        awslogs-region        = var.aws_region
        awslogs-stream-prefix = "ecs"
      }
    }
  }])

  tags = {
    Name        = "${var.project_name}-ai-service"
    Environment = var.environment
  }
}

# ─────────────────────────────────────────
# ECS Services — keeps containers running
# ─────────────────────────────────────────
resource "aws_ecs_service" "upload_service" {
  name            = "${var.project_name}-upload-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.upload_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.upload_service.arn
    container_name   = "upload-service"
    container_port   = 8080
  }

  tags = {
    Name        = "${var.project_name}-upload-service"
    Environment = var.environment
  }
}

resource "aws_ecs_service" "ai_service" {
  name            = "${var.project_name}-ai-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.ai_service.arn
  desired_count   = 1
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = aws_subnet.public[*].id
    security_groups  = [aws_security_group.ecs_tasks.id]
    assign_public_ip = true
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.ai_service.arn
    container_name   = "ai-service"
    container_port   = 8081
  }

  tags = {
    Name        = "${var.project_name}-ai-service"
    Environment = var.environment
  }
}
