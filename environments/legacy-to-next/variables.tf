# ============================================================
# 공통 / 식별
# ============================================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "iam_role_arn" {
  description = "Terraform provider가 assume할 IAM Role ARN. 빈 문자열이면 assume 안 함(CI/OIDC 환경자격 직접 사용). 로컬 기본값 = portfolio-terraform-role."
  type        = string
  default     = "arn:aws:iam::740636428516:role/portfolio-terraform-role"
}

variable "aws_profile" {
  description = "Terraform provider가 사용할 AWS 프로필. 빈 문자열이면 프로필 미지정(CI/OIDC 환경자격 직접 사용). 로컬 기본값 = portfolio."
  type        = string
  default     = "portfolio"
}

variable "project_name" {
  description = "리소스 이름 prefix"
  type        = string
  default     = "legacy-to-next"
}

# ============================================================
# DNS (기존 호스팅 영역 공유 — 신규 생성 안 함)
# ============================================================

variable "domain_name" {
  description = "기존 Route53 호스팅 영역 도메인. 서브도메인을 여기에 추가한다."
  type        = string
  default     = "nextcraft.click"
}

variable "api_subdomain" {
  description = "게이트웨이(CloudFront) 공개 서브도메인"
  type        = string
  default     = "api"
}

variable "app_subdomain" {
  description = "프론트엔드(Amplify) 서브도메인"
  type        = string
  default     = "app"
}

variable "origin_subdomain" {
  description = "CloudFront origin용 EC2 직결 서브도메인 (lifecycle 디커플링용 — CloudFront는 이 호스트명 문자열만 참조)"
  type        = string
  default     = "l2n-origin"
}

# ============================================================
# S3 (EDMS 첨부 — 기존 수동 생성 버킷 import)
# ============================================================

variable "s3_bucket_name" {
  description = "EDMS 첨부 S3 버킷 (기존 수동 생성분, terraform import 대상)"
  type        = string
  default     = "legacy-to-next"
}

variable "s3_key_prefix" {
  description = "EDMS 객체 prefix (IAM 정책 범위)"
  type        = string
  default     = "edms"
}

variable "s3_deploy_prefix" {
  description = "EC2 user-data가 내려받는 배포 번들(compose·seed·init) prefix"
  type        = string
  default     = "deploy"
}

# ============================================================
# 네트워크 / EC2
# ============================================================

variable "vpc_id" {
  description = "사용할 VPC ID (계정 default VPC)"
  type        = string
  default     = "vpc-0b5ea269fea455d52"
}

variable "ec2_ami" {
  description = "EC2 AMI (Amazon Linux 2023, 서울). dnf·SSM agent·cloud-init 포함"
  type        = string
  default     = "ami-0ada8527e6dc686a3"
}

variable "ec2_instance_type" {
  description = "EC2 인스턴스 유형 (5 JVM + Mongo + Redis = 8GB 권장). 대규모 작업 시 t3.2xlarge로 override"
  type        = string
  default     = "t3.large"
}

variable "ec2_root_volume_size" {
  description = "EC2 루트 EBS(gp3) GB — 이미지 5종 + Mongo/Redis + 로그"
  type        = number
  default     = 30
}

variable "ec2_key_name" {
  description = "EC2 키 페어 이름 (null이면 SSH 키 미연결, SSM Session Manager로 접속)"
  type        = string
  default     = null
}

variable "ssh_allowed_cidr" {
  description = "SSH(22) 허용 CIDR. 빈 문자열이면 SSH 인그레스 미개방(SSM 사용)"
  type        = string
  default     = ""
}

variable "app_port" {
  description = "게이트웨이 포트 (CloudFront origin·EC2 인그레스)"
  type        = number
  default     = 8084
}

# ============================================================
# RDS
# ============================================================

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스 (1k 시드면 micro 충분)"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL 버전 (앱 = 17.x)"
  type        = string
  default     = "17.5"
}

variable "db_allocated_storage" {
  description = "RDS 할당 스토리지 GB (gp3 Postgres 최소 = 20)"
  type        = number
  default     = 20
}

# ============================================================
# Amplify (프론트엔드 SSR) — 토큰 제공 시에만 생성
# ============================================================

variable "amplify_repo_url" {
  description = "프론트엔드 GitHub 저장소 URL"
  type        = string
  default     = "https://github.com/rerun1129/legacy-to-next"
}

variable "amplify_oauth_token" {
  description = "Amplify가 GitHub 저장소에 접근할 PAT. 빈 문자열이면 Amplify 리소스 미생성(수동 연결)."
  type        = string
  default     = ""
  sensitive   = true
}

variable "amplify_branch" {
  description = "Amplify가 빌드/배포할 브랜치"
  type        = string
  default     = "master"
}

# ============================================================
# CI/CD (GitHub Actions OIDC → ECR push)
# ============================================================

variable "github_repo" {
  description = "OIDC 신뢰 대상 — 앱(이미지 push) GitHub 저장소 (owner/repo)"
  type        = string
  default     = "rerun1129/legacy-to-next"
}

variable "infra_github_repo" {
  description = "OIDC 신뢰 대상 — 인프라(terraform lifecycle) GitHub 저장소 (owner/repo)"
  type        = string
  default     = "rerun1129/portfolio-infra"
}

variable "enable_cicd_oidc" {
  description = "GitHub Actions OIDC provider + ECR push 역할 생성 여부. 계정에 이미 token.actions.githubusercontent.com provider가 있으면 false로 두고 수동 push 사용."
  type        = bool
  default     = false
}
