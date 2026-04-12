# Apply 후 수동 작업 체크리스트

## EC2 apply 후

- [ ] 앱 배포 및 실행 (서버 설정, Docker 등 수동 작업)
  > EIP(52.78.180.13)는 고정이므로 접속 주소 변경 없음

---

## RDS apply 후

- [ ] 앱 커넥션 프로퍼티 확인
  > 엔드포인트는 destroy/apply 반복해도 변경되지 않음
  > `todolist-db.cdqpv9e2voky.ap-northeast-2.rds.amazonaws.com` 고정

- [ ] DB 스키마 재생성 (수동)
  > 스키마를 SQL로 덤프해둔 경우:
  ```bash
  psql -h <새 엔드포인트> -U postgres -f schema.sql
  ```

---

## CloudFront apply 후

- [ ] 도메인 확인
  ```bash
  terraform output cloudfront_domain
  ```
  > 출력 예: `https://dzcf5t1ap5pg3.cloudfront.net`

- [ ] 프론트엔드(Amplify) API_BASE_URL을 CloudFront 도메인으로 업데이트
  > Amplify 환경변수 또는 앱 설정 파일에서 EC2 직접 호출 URL → CloudFront URL로 교체

---

## 전체 apply 후

RDS가 포함된 경우 위 RDS 항목 동일하게 수행.
