# IAM (Identity and Access Management)

## 개요

Terraform이 AWS 리소스를 프로비저닝할 때 사용하는 자격증명 구조.
**IAM User + IAM Role Assume** 방식으로 최소 권한 원칙을 적용한다.

## 구성도

```
로컬 PC
  └─ ~/.aws/credentials [portfolio 프로파일]
       └─ IAM User: terraform-executor
            └─ sts:AssumeRole 권한만 보유
                 └─ IAM Role: portfolio-terraform-role
                      └─ 실제 AWS 리소스 관리 권한 (AdministratorAccess)
```

## 리소스 명세

### IAM User: `terraform-executor`

| 항목 | 값 |
|------|----|
| 목적 | 로컬 PC에서 AWS 인증 진입점 |
| 권한 | `sts:AssumeRole` (portfolio-terraform-role 대상만) |
| 자격증명 | Access Key (로컬 ~/.aws/credentials에 저장) |

**인라인 정책 예시:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "sts:AssumeRole",
      "Resource": "arn:aws:iam::740636428516:role/portfolio-terraform-role"
    }
  ]
}
```

### IAM Role: `portfolio-terraform-role`

| 항목 | 값 |
|------|----|
| 목적 | Terraform이 실제 AWS 리소스를 생성/수정/삭제하는 주체 |
| 권한 | AdministratorAccess (초기 단계, 추후 scoped로 변경 권장) |
| Trusted Entity | IAM User `terraform-executor` |

**Trust Policy 예시:**
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "AWS": "arn:aws:iam::740636428516:user/terraform-executor"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
```

## 로컬 설정

`~/.aws/credentials`:
```ini
[portfolio]
aws_access_key_id     = <IAM User Access Key>
aws_secret_access_key = <IAM User Secret Key>
```

## Terraform Provider 설정

`environments/*/main.tf`에 반영된 설정:
```hcl
provider "aws" {
  region  = var.aws_region
  profile = "portfolio"

  assume_role {
    role_arn = var.iam_role_arn
  }
}
```

`iam_role_arn` 값은 각 환경의 `terraform.tfvars`에서 지정:
```hcl
iam_role_arn = "arn:aws:iam::740636428516:role/portfolio-terraform-role"
```

## AWS 콘솔 초기 세팅 순서 (1회)

1. AWS 콘솔 → IAM → Roles → `portfolio-terraform-role` 생성
   - Trusted entity: Another AWS account (또는 IAM User)
   - 권한: `AdministratorAccess`

2. AWS 콘솔 → IAM → Users → `terraform-executor` 생성
   - Access Key 발급 후 안전한 곳에 저장
   - 인라인 정책: 위 `sts:AssumeRole` 정책 추가

3. 로컬 `~/.aws/credentials`에 Access Key 등록

4. `terraform.tfvars`의 `740636428516` 실제 계정 ID로 교체

## 관련 파일

- `environments/dev/main.tf`
- `environments/staging/main.tf`
- `environments/prod/main.tf`
- `environments/*/terraform.tfvars`
