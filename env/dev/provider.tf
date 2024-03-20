terraform {
  required_version = "~>1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.3.0"
    }
  }
  backend "s3" {
    bucket = "go-api-sample-todo-tfstate"
    key    = "dev-terraform.tfstate"
    region = "ap-northeast-1"
  }
}
