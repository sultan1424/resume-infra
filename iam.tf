# ─────────────────────────────────────────
# ECS Task Execution Role
# Allows ECS to pull images from ECR and write logs
# ─────────────────────────────────────────
resource "aws_iam_role" "ecs_execution_role" {
  name = "${var.project_name}-ecs-execution-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# ─────────────────────────────────────────
# ECS Task Role
# Allows the running containers to access AWS services
# (S3, DynamoDB, Bedrock, OpenSearch)
# ─────────────────────────────────────────
resource "aws_iam_role" "ecs_task_role" {
  name = "${var.project_name}-ecs-task-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ecs-tasks.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ecs_task_policy" {
  name = "${var.project_name}-ecs-task-policy"
  role = aws_iam_role.ecs_task_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        # S3 — read and write CV files
        Effect   = "Allow"
        Action   = ["s3:PutObject", "s3:GetObject", "s3:DeleteObject"]
        Resource = "${aws_s3_bucket.cv_storage.arn}/*"
      },
      {
        # DynamoDB — read and write analysis results
        Effect   = "Allow"
        Action   = ["dynamodb:PutItem", "dynamodb:GetItem", "dynamodb:UpdateItem", "dynamodb:Query"]
        Resource = aws_dynamodb_table.results.arn
      },
      {
        # Bedrock — invoke LLM and embedding models
        Effect   = "Allow"
        Action   = ["bedrock:InvokeModel"]
        Resource = "*"
      },
      {
        # OpenSearch — read and write vectors
        Effect   = "Allow"
        Action   = ["es:ESHttpGet", "es:ESHttpPost", "es:ESHttpPut"]
        Resource = "${aws_opensearch_domain.vector_store.arn}/*"
      }
    ]
  })
}
