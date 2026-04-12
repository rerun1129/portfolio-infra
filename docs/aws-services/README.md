# AWS 서비스 문서

이 디렉토리는 portfolio-infra에서 사용하는 AWS 서비스에 대한 설명과 설계 결정을 기록합니다.

## 문서 목록

| 파일 | 서비스 |
|------|--------|
| [iam.md](iam.md) | IAM - Terraform 실행용 User/Role 구성 |
| [s3.md](s3.md) | S3 - 오브젝트 스토리지 (수동 관리) |
| [rds.md](rds.md) | RDS - PostgreSQL 18.3 (apply/destroy로 관리) |
| [ec2.md](ec2.md) | EC2 - 애플리케이션 서버 (EIP 고정 보유) |
| [amplify.md](amplify.md) | Amplify - Next.js SSR 프론트엔드 호스팅 (수동 관리) |
| [cloudfront.md](cloudfront.md) | CloudFront - EC2 백엔드 HTTPS 프록시 (Terraform 관리) |

## 작성 규칙

각 서비스 문서는 다음 항목을 포함합니다:
- 서비스 개요 및 사용 목적
- 아키텍처 내 역할
- 주요 설정 및 고려사항
- 관련 Terraform 모듈 경로
