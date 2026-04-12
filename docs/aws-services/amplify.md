# Amplify (Frontend Hosting)

## 개요

todolist 프론트엔드(Next.js SSR)를 호스팅하는 서비스.
Git 레포지토리와 연동되어 push 시 자동 빌드 및 배포.

## 관리 방식

**Terraform 외부에서 수동 관리** (콘솔에서 직접 설정)

### 이유
- 사용량 기반 과금 — 유휴 비용 없음 (destroy할 이유가 없음)
- destroy 시 GitHub 연동 및 설정 초기화됨
- 월 비용: 사실상 $0 (소량 빌드·트래픽만 과금)

---

## 앱 정보

| 항목 | 값 |
|------|----|
| 앱 이름 | todolist-frontend |
| 앱 ID | d3iprkvplk2uky |
| 앱 ARN | arn:aws:amplify:ap-northeast-2:740636428516:apps/d3iprkvplk2uky |
| 플랫폼 | WEB_COMPUTE |
| 프레임워크 | Next.js - SSR |
| GitHub 레포 | https://github.com/rerun1129/todolist-frontend.git |
| 배포 브랜치 | master |
| 프로덕션 URL | https://master.d3iprkvplk2uky.amplifyapp.com |

---

## 환경 변수

AWS 콘솔 → Amplify → todolist-frontend → 환경 변수에서 관리.

| 변수명 | 현재 값 | 설명 |
|--------|---------|------|
| `NEXT_PUBLIC_API_URL` | `https://dzcf5t1ap5pg3.cloudfront.net/api` | 백엔드 API 엔드포인트 (CloudFront 도메인) |
| `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | `469542265119-5oe3fmaqj8p1rjk5nm5096fgnsp8t17e.apps.googleusercontent.com` | Google OAuth 클라이언트 ID |

> `NEXT_PUBLIC_API_URL` — CloudFront 도메인 변경 시 함께 업데이트 필요.
> `NEXT_PUBLIC_GOOGLE_CLIENT_ID` — Google Cloud Console → OAuth 2.0 클라이언트에서 확인.

---

## 빌드 설정 (amplify.yml)

```yaml
version: 1
frontend:
  phases:
    preBuild:
      commands:
        - npm ci --cache .npm --prefer-offline
    build:
      commands:
        - npm run build
  artifacts:
    baseDirectory: .next
    files:
      - '**/*'
  cache:
    paths:
      - .next/cache/**/*
      - .npm/**/*
```

---

## 배포 흐름

```
로컬 코드 수정
  → git push origin master
    → Amplify 자동 감지
      → 빌드 (npm ci → npm run build)
        → .next 아티팩트 배포
          → https://master.d3iprkvplk2uky.amplifyapp.com 반영
```

---

## 콘솔 바로가기

`AWS 콘솔 → Amplify → todolist-frontend`
