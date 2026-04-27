# ─────────────────────────────────────────
# Application Load Balancer
# ─────────────────────────────────────────
resource "aws_lb" "main" {
  name               = "${var.project_name}-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = aws_subnet.public[*].id

  tags = {
    Name        = "${var.project_name}-alb"
    Environment = var.environment
  }
}

# Target group for Upload Service
resource "aws_lb_target_group" "upload_service" {
  name        = "${var.project_name}-upload-tg"
  port        = 8080
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# Target group for AI Analysis Service
resource "aws_lb_target_group" "ai_service" {
  name        = "${var.project_name}-ai-tg"
  port        = 8081
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "ip"

  health_check {
    path                = "/health"
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }
}

# ALB Listener — routes traffic based on path
resource "aws_lb_listener" "main" {
  load_balancer_arn = aws_lb.main.arn
  port              = 80
  protocol          = "HTTP"

  # Default action — forward to upload service
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.upload_service.arn
  }
}

# Route /upload* → Upload Service
resource "aws_lb_listener_rule" "upload" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.upload_service.arn
  }

  condition {
    path_pattern {
      values = ["/upload*"]
    }
  }
}

# Route /results* and /analyze* → AI Analysis Service
resource "aws_lb_listener_rule" "ai" {
  listener_arn = aws_lb_listener.main.arn
  priority     = 200

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.ai_service.arn
  }

  condition {
    path_pattern {
      values = ["/results*", "/analyze*"]
    }
  }
}

# ─────────────────────────────────────────
# HTTP API Gateway (v2) — Factor 13: API First
# ─────────────────────────────────────────
resource "aws_apigatewayv2_api" "main" {
  name          = "${var.project_name}-api"
  protocol_type = "HTTP"

  cors_configuration {
    allow_origins = ["*"]
    allow_methods = ["GET", "POST", "OPTIONS"]
    allow_headers = ["Content-Type", "Authorization"]
  }

  tags = {
    Name        = "${var.project_name}-api"
    Environment = var.environment
  }
}

resource "aws_apigatewayv2_stage" "main" {
  api_id      = aws_apigatewayv2_api.main.id
  name        = "$default"
  auto_deploy = true
}

# Integration — API Gateway → ALB
resource "aws_apigatewayv2_integration" "alb" {
  api_id             = aws_apigatewayv2_api.main.id
  integration_type   = "HTTP_PROXY"
  integration_uri    = aws_lb_listener.main.arn
  integration_method = "ANY"

  connection_type = "VPC_LINK"
  connection_id   = aws_apigatewayv2_vpc_link.main.id
}

resource "aws_apigatewayv2_vpc_link" "main" {
  name               = "${var.project_name}-vpc-link"
  security_group_ids = [aws_security_group.alb.id]
  subnet_ids         = aws_subnet.public[*].id
}

# Catch-all route → forwards everything to ALB
resource "aws_apigatewayv2_route" "default" {
  api_id    = aws_apigatewayv2_api.main.id
  route_key = "ANY /{proxy+}"
  target    = "integrations/${aws_apigatewayv2_integration.alb.id}"
}
