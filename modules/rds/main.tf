# 使用する Aurora DB のエンジン、バージョン情報を定義
locals {
  master_username = "admin"
  engine          = "aurora-mysql"
  engine_version  = "8.0.mysql_aurora.3.02.0"
  instance_class  = "db.t4g.medium"
  database_name   = "todo"
}

# RDS
resource "aws_rds_cluster" "this" {
  cluster_identifier = "${var.env}-cluster-${local.database_name}"

  database_name                   = local.database_name
  master_username                 = local.master_username
  master_password                 = random_password.this.result
  availability_zones              = var.azs
  port                            = 3306
  vpc_security_group_ids          = [aws_security_group.this.id]
  db_subnet_group_name            = var.db_subnet_group_name
  db_cluster_parameter_group_name = aws_rds_cluster_parameter_group.this.id
  engine                          = local.engine
  engine_version                  = local.engine_version
  final_snapshot_identifier       = "${var.env}-cluster-final-snapshot-${local.database_name}"
  skip_final_snapshot             = true
  apply_immediately               = true

  tags = {
    Name        = "${var.env}-cluster-${local.database_name}"
    Terraform   = "true"
    Environment = var.env
  }

    lifecycle {
    ignore_changes = [
      availability_zones,
    ]
  }

}

resource "aws_rds_cluster_instance" "this" {
  count              = 1
  identifier         = "${var.env}-${local.database_name}-${count.index}"
  engine             = local.engine
  engine_version     = local.engine_version
  cluster_identifier = aws_rds_cluster.this.id
  instance_class     = local.instance_class
  
  tags = {
    Name        = "${var.env}-${local.database_name}-${count.index}"
    Terraform   = "true"
    Environment = var.env
  }
}

# master_username のパスワードを自動生成
resource "random_password" "this" {
  length           = 12
  special          = true
  override_special = "!#&,:;_"

  lifecycle {
    ignore_changes = [
      override_special
    ]
  }
}


resource "aws_rds_cluster_parameter_group" "this" {
  name   = "${var.env}-rds-cluster-parameter-group-${local.database_name}"
  family = "aurora-mysql8.0"

  parameter {
    name  = "time_zone"
    value = "Asia/Tokyo"
  }
}


# Security Group
resource "aws_security_group" "this" {
  name   = "${var.env}-sg-rds-${local.database_name}"
  vpc_id = var.vpc_id
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name        = "${var.env}-sg-rds-${local.database_name}"
    Terraform   = "true"
    Environment = var.env
  }
}

resource "aws_security_group_rule" "this" {
  type              = "ingress"
  from_port         = 3306
  to_port           = 3306
  protocol          = "tcp"
  cidr_blocks       = var.access_allow_cidr_blocks
  security_group_id = aws_security_group.this.id
}


# 各種パラメータを AWS Systems Manager Parameter Store へ保存
resource "aws_ssm_parameter" "master_username" {
  name      = "/${var.env}/rds/${local.database_name}/master_username"
  type      = "SecureString"
  value     = aws_rds_cluster.this.master_username

  tags = {
    Terraform   = "true"
    environment = var.env
  }
}
resource "aws_ssm_parameter" "master_password" {
  name  = "/${var.env}/rds/${local.database_name}/master_password"
  type  = "SecureString"
  value = aws_rds_cluster.this.master_password

  tags = {
    Terraform   = "true"
    environment = var.env
  }
}

resource "aws_ssm_parameter" "cluster_endpoint" {
  name      = "/${var.env}/rds/${local.database_name}/endpoint_w"
  type      = "SecureString"
  value     = aws_rds_cluster.this.endpoint

  tags = {
    Terraform   = "true"
    environment = var.env
  }
}

resource "aws_ssm_parameter" "cluster_reader_endpoint" {
  name      = "/${var.env}/rds/${local.database_name}/endpoint_r"
  type      = "SecureString"
  value     = aws_rds_cluster.this.reader_endpoint

  tags = {
    Terraform   = "true"
    environment = var.env
  }
}