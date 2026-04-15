# Trouble Shooting

AWS + Terraform 구축 과정에서 실제로 마주친 문제와 해결 방법을 정리합니다.
Obsidian LLM 위키 페이지 구성용 소스 문서입니다.

---

## 1. Terraform / IaC

### 보안 그룹 description mismatch로 replace 발생

**증상**
`terraform plan` 실행 시 보안 그룹에 `-/+` (destroy + create) 표시.

**원인**
AWS 보안 그룹의 `description`은 생성 후 수정 불가(immutable). 콘솔에서 생성 시 타임스탬프가 자동으로 붙은 description이 코드와 달라 Terraform이 replace를 시도함.

**해결**
```hcl
resource "aws_security_group" "main" {
  lifecycle {
    ignore_changes = [description]
  }
}
```

---

### 콘솔에서 생성한 RDS를 import할 때 plan diff 발생

**증상**
`terraform import` 후 `terraform plan`에서 여러 필드 변경 감지.

**원인**
콘솔 기본값과 코드 기본값이 다른 필드들이 존재함.

**실제 발생한 diff 목록**

| 필드 | 코드 값 | 실제 값 |
|------|--------|--------|
| `backup_retention_period` | 7 | 1 |
| `copy_tags_to_snapshot` | (없음) | true |
| `publicly_accessible` | false | true |

**해결**
`terraform plan` 출력을 보며 실제 값과 일치하도록 코드 수정 반복.

---

### CloudFront import 후 EC2 포트 mismatch

**증상**
콘솔에서 생성한 CloudFront를 import했더니 EC2 origin 포트가 80으로 설정되어 있어 실제 앱 포트(8080)와 불일치.

**원인**
CloudFront 콘솔 생성 마법사가 기본 포트를 80으로 설정.

**해결**
코드에서 `custom_origin_config.http_port = 8080` 으로 명시.

---

## 2. AWS CloudFront / WAF

### CloudFront 생성 시 WAF 자동 연결로 예상치 못한 과금

**증상**
콘솔에서 CloudFront 생성 후 WAF Web ACL(`CreatedByCloudFront`)이 자동으로 연결됨.

**원인**
CloudFront 생성 마법사의 "기본 보호 활성화" 옵션이 기본 체크 상태.

**비용**
WAF Web ACL 기본 과금 $5/월.

**해결**
포트폴리오 규모에서는 WAF 불필요. Terraform apply 시 WAF 연결 제거하여 절감.

---

### Amplify(HTTPS) → EC2(HTTP) 직접 호출 시 Mixed Content 오류

**증상**
프론트엔드에서 백엔드 API 호출 시 브라우저 콘솔에 Mixed Content 오류 발생, 요청 차단됨.

**원인**
HTTPS 페이지에서 HTTP 리소스를 로드하면 브라우저가 차단.

**해결**
CloudFront를 EC2 앞단에 배치하여 HTTPS 엔드포인트 제공.

```
Amplify (HTTPS) → CloudFront (HTTPS 종료) → EC2 (HTTP:8080)
```

---

## 3. AWS S3

### S3 퍼블릭 액세스 차단 후 기존 이미지 403 오류

**증상**
CloudFront OAC 설정 후 S3 퍼블릭 액세스를 차단하자 기존에 보이던 이미지들이 403.

**원인**
기존 코드가 S3 직접 URL(`s3.amazonaws.com/...`)을 사용하고 있었음.

**해결**
파일 업로드 후 저장/반환하는 URL을 S3 직접 URL에서 CloudFront URL로 변경.

```
전: https://todolist-dev-rerun1129.s3.ap-northeast-2.amazonaws.com/todos/...
후: https://dzcf5t1ap5pg3.cloudfront.net/todos/...
```

---

### S3 퍼블릭 버킷에서 CORS 오류

**증상**
Amplify에서 S3에 직접 fetch 시 CORS 오류 발생.

**원인**
S3 버킷에 CORS 설정이 없으면 브라우저가 Cross-Origin 요청을 차단.

**해결**
S3 버킷 Permissions → CORS에 허용 Origin 추가.

```json
[{
  "AllowedHeaders": ["*"],
  "AllowedMethods": ["GET"],
  "AllowedOrigins": [
    "https://nextcraft.click",
    "https://www.nextcraft.click"
  ],
  "MaxAgeSeconds": 3600
}]
```

---

## 4. AWS EIP

### 미연결 EIP 과금 (2024년 2월 정책 변경)

**증상**
EC2를 destroy한 상태에서 EIP를 보유만 해도 과금 발생.

**원인**
2024년 2월부터 AWS가 미연결 EIP에 $0.005/시간 과금 정책 도입. 월 $3.60 발생.

**해결**
EC2 destroy 시 EIP도 함께 release. 다음 세션에서 신규 발급 후 import.

```bash
# 다음 EC2 올릴 때
terraform import aws_eip.main <eipalloc-xxx>
terraform apply -target=aws_cloudfront_distribution.main -auto-approve  # origin IP 업데이트
terraform apply -target=aws_instance.main -target=aws_eip_association.main -auto-approve
```

---

## 5. 비용 분석

### RDS 과금 역산 시 인스턴스 시간만 계산하는 실수

**증상**
RDS $0.18을 인스턴스 시간으로만 역산하면 ~10시간으로 계산되나, 실제 사용은 3시간.

**원인**
RDS 과금 = 인스턴스 시간 + 스토리지 prorated 두 항목의 합산.

**정확한 역산 방법**
```
인스턴스: $0.028/hr × 3hr = $0.084  (db.t3.micro 기준)
스토리지: $0.138/GB × 20GB ÷ 30일 ÷ 24hr × 3hr = $0.012

합계: ~$0.096
```

스토리지 용량이 클수록 짧은 세션에서도 스토리지 비중이 커짐.
