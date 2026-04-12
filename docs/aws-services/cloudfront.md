# CloudFront (API HTTPS 프록시)

## 개요

EC2 백엔드(HTTP:8080) 앞에 위치해 HTTPS 엔드포인트를 제공.
Amplify 프론트엔드(HTTPS)에서 EC2를 직접 호출하면 Mixed Content 오류가 발생하기 때문에 사용.

## 관리 방식

**Terraform으로 관리** — `prevent_destroy = true` (삭제 보호)

### prevent_destroy 이유
- CloudFront 생성/삭제에 15분+ 소요
- 도메인이 바뀌면 프론트엔드 API_BASE_URL도 재설정 필요
- 사용량 기반 과금 — 유휴 비용 없음 (destroy할 이유가 없음)

---

## 배포 정보

| 항목 | 값 |
|------|----|
| Distribution ID | EQ5G8LNMI2WQL |
| 도메인 | https://dzcf5t1ap5pg3.cloudfront.net |
| Origin | EC2 EIP (52.78.180.13) HTTP:8080 |
| Viewer Protocol | redirect-to-https |
| Price Class | PriceClass_200 (미국·유럽·아시아 태평양, 한국 포함) |
| WAF | 없음 |
| 커스텀 도메인 | 없음 (기본 cloudfront.net 사용) |

---

## 아키텍처

```
Amplify (HTTPS)
  → CloudFront (HTTPS)  ← dzcf5t1ap5pg3.cloudfront.net
      ├─ todos/*   → S3 (todolist-dev-rerun1129)  ← 첨부파일
      ├─ editor/*  → S3 (todolist-dev-rerun1129)  ← 에디터 이미지
      └─ *         → EC2 (HTTP:8080) ← 52.78.180.13 → Spring Boot 앱
```

---

## Origin 설정

### EC2 Origin (기본)

| 항목 | 값 |
|------|----|
| 도메인 | 52.78.180.13 (EIP) |
| 포트 | 8080 |
| 프로토콜 | HTTP only |
| Cache Policy | CachingDisabled (`4135ea2d-6df8-44a3-9df3-4b5a84be39ad`) |
| Origin Request Policy | AllViewer (`216adef6-5c7f-47e4-b989-5492eafa07d3`) — 모든 헤더·쿼리·쿠키 전달 |

### S3 Origin

| 항목 | 값 |
|------|----|
| 버킷 | todolist-dev-rerun1129 |
| OAC ID | E1U6N248Y73X1I |
| 경로 패턴 | `todos/*`, `editor/*` |
| Cache Policy | CachingOptimized (`658327ea-f89d-4fab-a63d-7e88639e58f6`) |
| 퍼블릭 액세스 | 차단 (CloudFront OAC 전용) |

> S3 버킷 정책: `docs/aws-services/s3-bucket-policy.json` 참고

---

## 캐시 설정 요약

---

## 비용

- 요청: $0.0085/10,000건 (PriceClass_200, 아시아 태평양 기준)
- 데이터 전송: $0.114/GB (아시아 태평양 기준)
- 포트폴리오 트래픽 수준에서 월 $1 미만 예상

---

## Terraform 리소스

`environments/dev/main.tf` → `aws_cloudfront_distribution.main`

---

## 콘솔 바로가기

`AWS 콘솔 → CloudFront → EQ5G8LNMI2WQL`
