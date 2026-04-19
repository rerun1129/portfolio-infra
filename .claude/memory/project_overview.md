---
name: Project Overview
description: portfolio-infra 프로젝트의 전반적인 목적과 구조
type: project
---
Vive Coding 포트폴리오 서비스의 AWS 인프라를 Terraform으로 관리하는 프로젝트.

**Why:** 코드로 인프라를 관리하여 재현 가능하고 버전 관리 가능한 환경 구성.

**How to apply:** 새 AWS 리소스 추가 시 `environments/dev/main.tf`에 직접 작성. AWS 서비스 설명은 `docs/aws-services/` 하위에 md 파일로 누적 관리.

## 디렉토리 구조
- `environments/dev/` — 현재 유일한 활성 환경 (main.tf, variables.tf, outputs.tf, terraform.tfvars)
- `docs/aws-services/` — 사용 AWS 서비스 문서

## 기본 설정
- AWS 리전: ap-northeast-2 (서울)
- Terraform: >= 1.5.0, AWS Provider: ~> 5.0
- default_tags: Project=portfolio, Environment=<env>, ManagedBy=terraform
