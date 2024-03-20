# ALB
resource "aws_lb" "this" {
  name = "${var.env}-alb"

  internal           = false
  load_balancer_type = "application"
  subnets            = var.subnets

  security_groups = [aws_security_group.this.id]
  tags = {
    Name        = "${var.env}-alb"
    Terraform   = "true"
    Environment = var.env
  }
}

# SecurityGroup
resource "aws_security_group" "this" {
  name   = "${var.env}-sg-alb"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]

  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-sg-alb"
    Terraform   = "true"
    Environment = var.env
  }
}