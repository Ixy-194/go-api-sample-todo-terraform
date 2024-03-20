# クラスター定義
resource "aws_ecs_cluster" "this" {
  name = "${var.env}-ecs-cluster-${var.service_name}"

  tags = {
    Name        = "${var.env}-ecs-cluster-${var.service_name}"
    Terraform   = "true"
    Environment = var.env
  }
}

# サービス定義
resource "aws_ecs_service" "this" {
  name            = "${var.env}-ecs-service-${var.service_name}"
  cluster         = aws_ecs_cluster.this.id
  task_definition = aws_ecs_task_definition.this.arn

  desired_count    = 1
  launch_type      = "FARGATE"
  platform_version = "1.4.0"

  network_configuration {
    subnets         = var.subnets
    security_groups = [aws_security_group.this.id]
  }
  
  # ALB との紐付け
  load_balancer {
    target_group_arn = aws_lb_target_group.this.arn
    container_name   = var.service_name
    container_port   = "80"
  }

  lifecycle {
    ignore_changes = [desired_count, task_definition]
  }

  tags = {
    Name        = "${var.env}-ecs-service-${var.service_name}"
    Terraform   = "true"
    Environment = var.env
  }
}

# タスク定義
resource "aws_ecs_task_definition" "this" {
  family                   = "${var.env}-task-definition-${var.service_name}"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = 256
  memory                   = 512
  container_definitions = jsonencode([
    {
      name = var.service_name
      # 暫定で nginx を立てる
      # 別途 CD でイメージを上書きする
      image = "nginx:latest"
      logConfiguration : {
        logDriver : "awslogs",
        options : {
          awslogs-region : "ap-northeast-1",
          awslogs-stream-prefix : var.service_name,
          awslogs-group : "/ecs/${var.service_name}/${var.env}"
        }

      }
      portMappings = [
        {
          containerPort = 80
        }
      ]
    }
  ])
  task_role_arn      = aws_iam_role.this.arn
  execution_role_arn = aws_iam_role.this.arn

  tags = {
    Name        = "${var.env}-task-definition-${var.service_name}"
    Terraform   = "true"
    Environment = var.env
  }
}

# ターゲットグループの作成
resource "aws_lb_target_group" "this" {
  name = "${var.env}-alb-tg-${var.service_name}"

  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = var.vpc_id

  tags = {
    Name        = "${var.env}-alb-tg-${var.service_name}"
    Terraform   = "true"
    Environment = var.env
  }
}

# listener の作成
resource "aws_lb_listener" "http" {
  port     = "80"
  protocol = "HTTP"
  load_balancer_arn = var.lb.arn

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.this.arn
  }

  tags = {
    Name        = "${var.env}-lb-http-listener-${var.service_name}"
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_security_group" "this" {
  name        = "${var.env}-sg-${var.service_name}"
  description = "${var.env}-sg-${var.service_name}"
  vpc_id      = var.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [var.lb_security_group_id]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-sg-${var.service_name}"
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_cloudwatch_log_group" "this" {
  name = "/ecs/${var.service_name}/${var.env}"
}


# 実行ロール
resource "aws_iam_role" "this" {
  name = "${var.env}-ecs-execution-role-${var.service_name}"

  assume_role_policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "ecs-tasks.amazonaws.com"
      },
      "Effect": "Allow",
      "Sid": ""
    }
  ]
}
EOF
}
resource "aws_iam_role_policy" "this" {
  name = "${var.env}-ecs-execution-role-policy-${var.service_name}"
  role = aws_iam_role.this.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "ssm:GetParameters",
          "secretsmanager:GetSecretValue",
        ]
        Effect   = "Allow"
        Resource = "*"
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "this" {
  role       = aws_iam_role.this.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
