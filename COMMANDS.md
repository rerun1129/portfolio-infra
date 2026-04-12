# Terraform 명령어 가이드

## 사전 준비

환경변수 설정 (터미널 실행 시마다 필요):
```bash
export TF_VAR_db_password="패스워드"
```

작업 디렉토리 이동:
```bash
cd environments/dev      # 개발 환경
cd environments/staging  # 스테이징 환경
cd environments/prod     # 프로덕션 환경
```

최초 1회 또는 provider/backend 변경 시:
```bash
terraform init
```

---

## 전체 Apply (EC2 + RDS 생성)

```bash
terraform apply -auto-approve
```

실제 변경 전 미리보기:
```bash
terraform plan
```

> EIP, CloudFront는 이미 올라가 있어 변경 없음. EC2, RDS가 주요 생성 대상.
> **Apply 후 수동 작업 필요** → [POST-APPLY-CHECKLIST.md](../POST-APPLY-CHECKLIST.md) 확인

---

## 전체 Destroy (EC2 + RDS 삭제)

> EIP와 CloudFront는 `prevent_destroy = true` — `terraform destroy`로 삭제되지 않음.
> 아래 명령으로 EC2, RDS만 내려감.

```bash
terraform destroy -target=aws_eip_association.main -target=aws_instance.main -target=aws_db_instance.main -auto-approve
```

---

## 서비스별 개별 Apply / Destroy

### EC2

```bash
# 생성 (EIP association 포함)
terraform apply -target=aws_instance.main -target=aws_eip_association.main -auto-approve

# 삭제 (EIP는 유지, association만 해제)
terraform destroy -target=aws_eip_association.main -target=aws_instance.main -auto-approve
```

> EC2는 EIP 고정이라 apply 후 별도 작업 없음.

### RDS (PostgreSQL)

```bash
# 생성
terraform apply -target=aws_db_instance.main -auto-approve

# 삭제
terraform destroy -target=aws_db_instance.main -auto-approve
```

> **RDS Apply 후 수동 작업 필요** → [POST-APPLY-CHECKLIST.md](../POST-APPLY-CHECKLIST.md) 확인

### CloudFront

```bash
# 설정 변경 적용 (생성 포함)
terraform apply -target=aws_cloudfront_distribution.main -auto-approve

# 도메인 확인
terraform output cloudfront_domain
```

> CloudFront는 `prevent_destroy = true` — destroy로 삭제되지 않음 (생성/삭제 15분+ 소요).
> **CloudFront Apply 후** → [POST-APPLY-CHECKLIST.md](../POST-APPLY-CHECKLIST.md) 확인

---

## 서비스 추가 시 참고

| 서비스 | 리소스 타입 | target 예시 |
|--------|------------|-------------|
| RDS | `aws_db_instance` | `-target=aws_db_instance.main` |
| EC2 | `aws_instance` | `-target=aws_instance.main` |
| ECS | `aws_ecs_service` | `-target=aws_ecs_service.main` |
| ALB | `aws_lb` | `-target=aws_lb.main` |
| VPC | `aws_vpc` | `-target=aws_vpc.main` |

> S3, Amplify는 Terraform 외부에서 수동 관리 (콘솔 사용).
> CloudFront는 `prevent_destroy = true` — destroy 명령으로 삭제되지 않음.

---

## 상태 확인

```bash
# 현재 Terraform이 관리 중인 리소스 목록
terraform state list

# 특정 리소스 상세 상태 확인
terraform state show aws_db_instance.main
```
