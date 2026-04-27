# OpenSearch domain — vector store for RAG pipeline
resource "aws_opensearch_domain" "vector_store" {
  domain_name    = "${var.project_name}-vectors"
  engine_version = "OpenSearch_2.11"

  cluster_config {
    instance_type  = "t3.small.search"
    instance_count = 1
  }

  ebs_options {
    ebs_enabled = true
    volume_size = 10  # GB
  }

  encrypt_at_rest {
    enabled = true
  }

  node_to_node_encryption {
    enabled = true
  }

  domain_endpoint_options {
    enforce_https = true
  }

  tags = {
    Name        = "${var.project_name}-vectors"
    Environment = var.environment
  }
}

# Access policy — only ECS task role can access OpenSearch
resource "aws_opensearch_domain_policy" "vector_store" {
  domain_name = aws_opensearch_domain.vector_store.domain_name

  access_policies = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect    = "Allow"
        Principal = { AWS = aws_iam_role.ecs_task_role.arn }
        Action    = "es:*"
        Resource  = "${aws_opensearch_domain.vector_store.arn}/*"
      }
    ]
  })
}
