---
name: Project State
description: 현재 AWS 인프라 실행 상태 및 남은 작업
type: project
---

## 현재 인프라 상태 (2026-04-15 기준)

**실행 중:**
- CloudFront (EQ5G8LNMI2WQL) — prevent_destroy
- S3 (todolist-dev-rerun1129) — Terraform state 보관 중, 삭제 금지
- S3 (nextcraft-portfolio-assets) — nextcraft 포트폴리오용 퍼블릭 버킷
- Route 53 호스팅 영역 (nextcraft.click) — $0.50/월
- Amplify (d3iprkvplk2uky)

**내려간 상태:**
- EC2 — destroy됨
- RDS — destroy됨
- EIP — release됨 (다음 EC2 올릴 때 신규 발급 후 import 필요)

**월 예상 과금:** ~$0.50-1.00

## 남은 작업

- RDS 인스턴스 타입 확인 (db.t3.small → db.t3.micro 검토)

**Why:** EC2/RDS는 비용 절감을 위해 사용할 때만 올리고 destroy하는 운영 방식
**How to apply:** EC2 올릴 때 EIP 신규 발급 → terraform import → CloudFront 업데이트 순서 안내
