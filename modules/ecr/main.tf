# ECR のポジトリを作成
resource "aws_ecr_repository" "this" {
  name                 = var.service_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name        = "${var.env}-ecr-${var.service_name}"
    Terraform   = "true"
    Environment = var.env
  }
}