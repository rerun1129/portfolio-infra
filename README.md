# portfolio-infra

Vive Coding 포트폴리오 서비스의 AWS 인프라를 Terraform으로 관리하는 저장소입니다.

비용 최적화를 핵심 목적으로, `terraform apply`로 인프라를 올리고 `terraform destroy`로 내리는 생명주기 관리를 기반으로 합니다.

## 아키텍처

```
GitHub (Next.js)
  → Amplify (HTTPS)
      ↓ API 호출
  CloudFront (HTTPS)
      ├─ todos/*, editor/*  → S3 (정적 파일)
      └─ *                  → EC2 (Spring Boot :8080)
                                  → RDS (PostgreSQL)
```

## Terraform 관리 범위

| 서비스 | 관리 방식 | destroy 가능 |
|--------|----------|:-----------:|
| EC2, 보안그룹 | Terraform | O |
| RDS | Terraform | O |
| EIP | Terraform | X (prevent_destroy) |
| CloudFront, OAC | Terraform | X (prevent_destroy) |
| S3, Amplify, IAM | 수동 (콘솔) | — |

## 디렉토리 구조

```
portfolio-infra/
├── environments/
│   └── dev/               # Terraform 루트 모듈 (main.tf, variables.tf, ...)
├── modules/               # 재사용 가능한 Terraform 모듈
└── docs/
    ├── setup-log.md       # 구축 과정 의사결정 기록 (Q&A 형식)
    └── aws-services/      # 서비스별 설정 문서
```

## 시작하기

```bash
cd environments/dev
terraform init    # S3 백엔드에서 state 자동으로 가져옴
terraform plan
terraform apply
```

`~/.aws/credentials`에 `[portfolio]` 프로파일이 설정되어 있어야 합니다.

## EC2/RDS 올릴 때

EIP가 release된 상태라면 먼저 AWS 콘솔에서 EIP를 새로 발급한 뒤:

```bash
terraform import aws_eip.main <eipalloc-xxx>
terraform apply -target=aws_instance.main -target=aws_eip_association.main -auto-approve
```

자세한 내용은 [docs/setup-log.md](docs/setup-log.md)를 참고하세요.
