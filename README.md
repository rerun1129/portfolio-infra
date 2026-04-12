# portfolio-infra

Vive Coding 포트폴리오 서비스의 AWS 인프라를 Terraform으로 관리하는 저장소입니다.

## 디렉토리 구조

```
portfolio-infra/
├── environments/          # 환경별 Terraform 루트 모듈
│   ├── dev/               # 개발 환경
│   ├── staging/           # 스테이징 환경
│   └── prod/              # 프로덕션 환경
├── modules/               # 재사용 가능한 Terraform 모듈
└── docs/
    └── aws-services/      # 사용 중인 AWS 서비스 설명 문서
```

## 환경별 구성

| 환경 | 설명 |
|------|------|
| dev | 개발 및 테스트용 |
| staging | 프로덕션 배포 전 검증용 |
| prod | 실제 서비스 운영 환경 |

## 시작하기

```bash
cd environments/<env>
terraform init
terraform plan
terraform apply
```
