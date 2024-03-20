
# 共通的に使用する値を変数として定義
locals {
  env = "dev"

  cidr = "192.168.1.0/24"
  public_subnets = ["192.168.1.64/28", "192.168.1.80/28"]
  private_subnets = ["192.168.1.32/28", "192.168.1.48/28"]
  rds_subnets = ["192.168.1.0/28", "192.168.1.16/28"]
  azs = ["ap-northeast-1a", "ap-northeast-1c"]
  service_name = "go-api-sample-todo"
}

module "vpc" {
  source = "../../modules/vpc"

  cidr            = local.cidr
  public_subnets  = local.public_subnets
  private_subnets = local.private_subnets
  rds_subnets     = local.rds_subnets
  azs             = local.azs
  env             = local.env
}

module "alb" {
  source = "../../modules/alb"

  env     = local.env
  vpc_id  = module.vpc.vpc.vpc_id
  subnets = module.vpc.vpc.public_subnets
}

module "ecs" {
  source = "../../modules/ecs"

  env                  = local.env
  vpc_id               = module.vpc.vpc.vpc_id
  subnets              = module.vpc.vpc.private_subnets
  lb                   = module.alb.lb
  lb_security_group_id = module.alb.lb_security_group_id
  service_name         = local.service_name
}

module "rds" {
  source = "../../modules/rds"

  env                      = local.env
  vpc_id                   = module.vpc.vpc.vpc_id
  azs                      = local.azs
  db_subnet_group_name     = module.vpc.vpc.database_subnet_group
  access_allow_cidr_blocks = module.vpc.vpc.private_subnets_cidr_blocks
}

module "bastion" {
  source = "../../modules/bastion"

  env       = local.env
  vpc_id    = module.vpc.vpc.vpc_id
  subnet_id = module.vpc.vpc.private_subnets[0]
}

module "ecr" {
  source = "../../modules/ecr"

  env          = local.env
  service_name = local.service_name
}

