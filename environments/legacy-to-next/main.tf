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
  #
  # 인증은 partial config로 분리(이중화):
  #   로컬:  terraform init -backend-config=backend.local.hcl   (profile=portfolio + assume portfolio-terraform-role)
  #          (기존 init 디렉토리면 -reconfigure 추가: terraform init -reconfigure -backend-config=backend.local.hcl)
  #   CI:    terraform init                                     (GitHub Actions OIDC 환경자격 — profile/assume 없음)
  backend "s3" {
    bucket = "todolist-dev-rerun1129"
    key    = "tfstate/legacy-to-next/dev/terraform.tfstate"
    region = "ap-northeast-2"
  }
}

# 로컬은 profile+assume_role(기본값), CI(OIDC)는 var.aws_profile=""·var.iam_role_arn="" 로
# 둘 다 비활성화해 환경 자격을 그대로 사용한다. 기본값이 로컬값이라 기존 로컬 흐름은 무변화.
provider "aws" {
  region  = var.aws_region
  profile = var.aws_profile != "" ? var.aws_profile : null

  dynamic "assume_role" {
    for_each = var.iam_role_arn != "" ? [1] : []
    content {
      role_arn = var.iam_role_arn
    }
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
  profile = var.aws_profile != "" ? var.aws_profile : null

  dynamic "assume_role" {
    for_each = var.iam_role_arn != "" ? [1] : []
    content {
      role_arn = var.iam_role_arn
    }
  }

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = "dev"
      ManagedBy   = "terraform"
    }
  }
}
