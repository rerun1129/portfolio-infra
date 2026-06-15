terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  # todolist와 동일 state 버킷을 공유하되 key를 분리해 상태 파일을 격리한다.
  # (todolist state = tfstate/dev/... 는 절대 건드리지 않음)
  backend "s3" {
    bucket  = "todolist-dev-rerun1129"
    key     = "tfstate/legacy-to-next/dev/terraform.tfstate"
    region  = "ap-northeast-2"
    profile = "portfolio"

    assume_role = {
      role_arn = "arn:aws:iam::740636428516:role/portfolio-terraform-role"
    }
  }
}

provider "aws" {
  region  = var.aws_region
  profile = "portfolio"

  assume_role {
    role_arn = var.iam_role_arn
  }

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}

# CloudFront용 ACM 인증서는 us-east-1에만 존재할 수 있어 별도 alias provider가 필요하다.
# (Phase D의 aws_acm_certificate에서 provider = aws.us_east_1 로 사용)
provider "aws" {
  alias   = "us_east_1"
  region  = "us-east-1"
  profile = "portfolio"

  assume_role {
    role_arn = var.iam_role_arn
  }

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
