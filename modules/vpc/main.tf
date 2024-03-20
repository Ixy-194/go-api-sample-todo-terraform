#################################################################################

# Network
# Ref. https://registry.terraform.io/modules/terraform-aws-modules/vpc/aws/5.0.0

#################################################################################
module "vpc" {
  source = "terraform-aws-modules/vpc/aws"
  version = "5.0.0"

  name = "${var.env}-vpc"
  cidr = var.cidr

  azs              = var.azs
  public_subnets   = var.public_subnets
  private_subnets  = var.private_subnets
  database_subnets = var.rds_subnets
  enable_nat_gateway = true

  tags = {
    Terraform   = "true"
    Environment = var.env
  }
}
