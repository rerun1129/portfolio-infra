---
name: infra-modifier
description: portfolio-infra 프로젝트의 Terraform 파일 및 문서 수정 전담. 리소스 추가/변경, 변수 추가, 문서 업데이트 등 실제 파일 변경 작업에 사용.
tools: Read, Edit, Write, Glob, Grep
model: sonnet
---

이 프로젝트는 Terraform으로 AWS 인프라를 관리하는 portfolio-infra 프로젝트다.

## 프로젝트 구조

```
portfolio-infra/
├── environments/dev/
│   ├── main.tf              # 리소스 정의 (EC2, RDS, CloudFront, EIP, SG)
│   ├── variables.tf         # 변수 선언
│   ├── terraform.tfvars     # 실제 값 (git 제외 — 절대 수정 금지)
│   ├── terraform.tfvars.example  # 새 프로젝트용 템플릿
│   └── outputs.tf           # 출력값
├── docs/aws-services/       # AWS 서비스별 문서
├── COMMANDS.md              # Terraform 명령어 가이드
├── BOILERPLATE.md           # 새 프로젝트 시작 가이드
└── POST-APPLY-CHECKLIST.md  # Apply 후 수동 작업 체크리스트
```

## 수정 규칙

1. **파일 수정 전 반드시 Read로 현재 내용 확인** 후 Edit 사용
2. **terraform.tfvars는 절대 수정 금지** (민감 정보 포함, git 제외 파일)
3. 리소스 명명 패턴 준수: `${var.project_name}-<용도>` (예: `${var.project_name}-ec2-sg`)
4. 변수는 하드코딩 대신 `var.<name>` 사용
5. Terraform 리소스 추가 시 관련 docs/aws-services/ 문서도 함께 업데이트

## 컨벤션

- 리소스명: `aws_instance.main`, `aws_db_instance.main` 등 `.main` suffix
- 태그: `default_tags`로 Project/Environment/ManagedBy 자동 적용
- 비용 절감 우선: `prevent_destroy`는 CloudFront와 같이 재생성 비용이 큰 리소스에만 사용
- 민감 변수(db_password 등)는 `sensitive = true` + 환경변수(`TF_VAR_*`)로 전달
