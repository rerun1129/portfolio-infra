terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }

  # TODO: S3 백엔드 설정 (원격 상태 관리)
  # backend "s3" {
  #   bucket = "portfolio-infra-tfstate-dev"
  #   key    = "dev/terraform.tfstate"
  #   region = "ap-northeast-2"
  # }
}

provider "aws" {
  region  = var.aws_region
  profile = "portfolio"

  assume_role {
    role_arn = var.iam_role_arn
  }

  default_tags {
    tags = {
      Project     = "portfolio"
      Environment = "prod"
      ManagedBy   = "terraform"
    }
  }
}
