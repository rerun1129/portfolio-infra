# 새 프로젝트 시작 가이드

이 Terraform 프로젝트를 보일러플레이트로 사용하는 방법입니다.

---

## AWS 콘솔 사전 작업 (1회)

### 1. 키 페어 생성
`EC2 → 키 페어 → 키 페어 생성`
- 이름: `<프로젝트명>-ec2-key`
- 형식: `.pem` 다운로드 후 보관

### 2. 탄력적 IP 할당 (선택)
`EC2 → 탄력적 IP → 탄력적 IP 주소 할당`
- 고정 IP가 필요한 경우에만 진행
- 할당 ID(`eipalloc-xxx`) 메모

### 3. S3 버킷 생성
`S3 → 버킷 만들기`
- 이름: `<프로젝트명>-<용도>` (예: `myblog-assets`)
- 리전: ap-northeast-2
- 퍼블릭 액세스 차단 활성화 (CloudFront OAC로만 접근)
- 생성 후 CloudFront 배포 시 OAC 연결 및 버킷 정책 적용 필요

---

## Terraform 설정

### 1. terraform.tfvars 작성
`environments/dev/terraform.tfvars.example`을 복사해서 수정합니다.

```bash
cp environments/dev/terraform.tfvars.example environments/dev/terraform.tfvars
```

**반드시 수정할 항목:**

| 항목 | 설명 |
|------|------|
| `project_name` | 프로젝트명 (리소스 이름 prefix) |
| `ec2_key_name` | 위에서 생성한 키 페어 이름 |
| `ssh_allowed_cidr` | 내 IP (https://ifconfig.me 에서 확인) |
| `s3_bucket_name` | 위에서 생성한 S3 버킷 이름 |

**동일 AWS 계정이면 그대로 써도 되는 항목:**

| 항목 | 기본값 | 설명 |
|------|--------|------|
| `vpc_id` | `vpc-0b5ea269fea455d52` | 계정 default VPC |
| `rds_security_group_id` | `sg-0df35a4a18482821d` | 계정 default 보안 그룹 |
| `iam_role_arn` | `arn:aws:iam::740636428516:role/...` | Terraform 실행 역할 |
| `ec2_ami` | `ami-0ada8527e6dc686a3` | Amazon Linux 2023 (서울) |

### 2. 패스워드 환경변수 설정

```bash
export TF_VAR_db_password="패스워드"
```

---

## 인프라 실행

```bash
cd environments/dev
terraform init
terraform apply -auto-approve
```

### 기존 EIP가 있는 경우 (import)
콘솔에서 미리 발급한 EIP가 있다면 import 후 apply:

```bash
terraform import aws_eip.main <eipalloc-xxx>
terraform apply -auto-approve
```

### EIP 없이 새로 생성하는 경우
그냥 `terraform apply` 하면 EIP까지 자동 생성됩니다.

---

## Apply 후 확인

- EC2 접속 IP: `terraform state show aws_eip.main | grep public_ip`
- RDS 엔드포인트: `terraform state show aws_db_instance.main | grep address`
  - ⚠️ 동일 identifier면 destroy/apply 반복해도 엔드포인트 변경 없음

---

## 리소스 이름 규칙

`project_name` 변수 값이 prefix로 자동 적용됩니다.

| 리소스 | 이름 패턴 | 예시 (`project_name = "myblog"`) |
|--------|----------|----------------------------------|
| EC2 Name 태그 | `{project_name}-server` | `myblog-server` |
| 보안 그룹 | `{project_name}-ec2-sg` | `myblog-ec2-sg` |
| RDS 식별자 | `{project_name}-db` | `myblog-db` |

---

## 서비스별 올리기/내리기

```bash
# EC2만
terraform apply  -target=aws_instance.main -target=aws_eip_association.main -auto-approve
terraform destroy -target=aws_eip_association.main -target=aws_instance.main -auto-approve

# RDS만
terraform apply  -target=aws_db_instance.main -auto-approve
terraform destroy -target=aws_db_instance.main -auto-approve

# 전체
terraform apply  -auto-approve
terraform destroy -auto-approve  # EIP는 prevent_destroy로 보호됨
```

---

## 파일 구조

```
environments/dev/
├── main.tf                   # 리소스 정의
├── variables.tf              # 변수 선언
├── terraform.tfvars          # 현재 프로젝트 값 (git 제외 권장)
├── terraform.tfvars.example  # 새 프로젝트 시작용 템플릿
└── outputs.tf                # 출력값 (필요 시 추가)
```
