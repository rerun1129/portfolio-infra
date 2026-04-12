# ============================================================
# 공통 설정
# ============================================================

variable "aws_region" {
  description = "AWS 리전"
  type        = string
  default     = "ap-northeast-2"
}

variable "iam_role_arn" {
  description = "Terraform이 assume할 IAM Role ARN"
  type        = string
}

# ============================================================
# 프로젝트 식별
# ============================================================

variable "project_name" {
  description = "프로젝트 이름 (리소스 이름 prefix로 사용 예: todolist, myblog)"
  type        = string
}

variable "vpc_id" {
  description = "사용할 VPC ID (기본값: 계정 default VPC)"
  type        = string
  default     = "vpc-0b5ea269fea455d52"
}

# ============================================================
# EC2
# ============================================================

variable "ec2_ami" {
  description = "EC2 AMI ID (기본값: Amazon Linux 2023 서울 리전)"
  type        = string
  default     = "ami-0ada8527e6dc686a3"
}

variable "ec2_instance_type" {
  description = "EC2 인스턴스 유형"
  type        = string
  default     = "t3.micro"
}

variable "ec2_key_name" {
  description = "EC2 키 페어 이름"
  type        = string
}

variable "ssh_allowed_cidr" {
  description = "SSH 접속 허용 IP (CIDR 형식, 예: 1.2.3.4/32)"
  type        = string
}

variable "app_port" {
  description = "애플리케이션 포트"
  type        = number
  default     = 8080
}

# ============================================================
# S3
# ============================================================

variable "s3_bucket_name" {
  description = "S3 버킷 이름 (CloudFront origin으로 사용, Terraform 외부에서 수동 관리)"
  type        = string
}

# ============================================================
# RDS
# ============================================================

variable "db_instance_class" {
  description = "RDS 인스턴스 클래스"
  type        = string
  default     = "db.t3.micro"
}

variable "db_engine_version" {
  description = "PostgreSQL 버전"
  type        = string
  default     = "18.3"
}

variable "db_password" {
  description = "RDS 마스터 패스워드 (환경변수로 전달: export TF_VAR_db_password=...)"
  type        = string
  sensitive   = true
}

variable "rds_security_group_id" {
  description = "RDS에 적용할 보안 그룹 ID (기본값: 계정 default VPC 보안 그룹)"
  type        = string
  default     = "sg-0df35a4a18482821d"
}
