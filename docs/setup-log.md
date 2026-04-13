# 인프라 구성 세션 로그

이 문서는 portfolio-infra 구축 과정에서 논의된 주요 결정 사항과 배경을 Q&A 형식으로 기록합니다.

---

## 1. 프로젝트 개요

**Q. 이 Terraform 프로젝트로 무엇을 관리하나?**

AWS에서 todolist 포트폴리오 서비스를 운영하기 위한 인프라를 코드로 관리.
`terraform apply`로 인프라를 올리고, `terraform destroy`로 내리는 생명주기 관리가 핵심 목적.
비용 절감을 위해 사용하지 않을 때는 destroy해두고 필요할 때 다시 apply.

관리 대상:
- **EC2** — Spring Boot 애플리케이션 서버
- **RDS** — PostgreSQL 데이터베이스
- **CloudFront** — HTTPS 엔드포인트 제공 (EC2/S3 앞단)
- **EIP** — EC2 고정 IP (destroy해도 보존)
- **보안 그룹** — EC2 인바운드/아웃바운드 규칙

Terraform 외부에서 수동 관리:
- **S3** — 데이터 손실 위험, destroy 불필요
- **Amplify** — destroy 시 GitHub 연동 초기화됨
- **IAM** — 부트스트랩 문제로 최초 1회 수동 생성

---

## 2. IAM / 자격증명 구성

**Q. IAM 정책 및 사용자도 Terraform에 등록해야 하나?**

Terraform으로 Terraform 실행 계정 자체를 만드는 것은 닭이 먼저냐 달걀이 먼저냐 문제(부트스트랩 문제)가 있어, 최초 1회는 AWS 콘솔에서 수동 생성해야 한다. 이후 `terraform import`로 가져와 관리하는 것은 가능하지만, IAM User/Role은 변경이 거의 없으므로 수동 관리로 충분하다.

**Q. IAM User와 IAM Role을 굳이 분리해서 쓰는 이유는?**

단순히 IAM User에 모든 권한을 주는 방식(옵션 1)과 IAM Role Assume 방식(옵션 2)의 차이:

- **옵션 1 (User 직접 권한)**: Access Key가 유출되면 그 키로 바로 AWS 리소스 전체 조작 가능
- **옵션 2 (Role Assume)**: Access Key가 유출되어도 `sts:AssumeRole` 권한만 있어 단독으로는 아무것도 못 함. 실제 권한은 Role에만 존재하고, Role을 Assume하는 행위 자체를 CloudTrail로 추적 가능

구성:
```
로컬 ~/.aws/credentials [portfolio 프로파일]
  └─ IAM User: terraform-executor
       └─ 인라인 정책: sts:AssumeRole (portfolio-terraform-role 대상만)
            └─ IAM Role: portfolio-terraform-role (AdministratorAccess)
```

Terraform provider 설정:
```hcl
provider "aws" {
  region  = "ap-northeast-2"
  profile = "portfolio"        # ~/.aws/credentials 프로파일
  assume_role {
    role_arn = var.iam_role_arn  # portfolio-terraform-role ARN
  }
}
```

**Q. 기존 IAM User에 인라인 정책을 추가하는 건 기존 정책을 대체하나 추가하나?**

추가다. AWS IAM에서 인라인 정책은 여러 개를 가질 수 있고, 기존 정책과 병존한다. 이미 있던 AdministratorAccess 정책이 있었던 경우, `sts:AssumeRole` 전용 정책을 별도로 추가하고 기존 과도한 권한은 제거하는 방향으로 정리.

---

## 3. S3 관리 방식 결정

**Q. S3를 Terraform apply/destroy 대상에 넣어야 할까?**

S3는 켜고 끄는 개념이 없다. destroy 시 버킷 내 모든 데이터가 삭제되는 위험이 있고, 1GB 이하 사용 시 월 $0.025(약 34원) 수준으로 유휴 비용도 사실상 없다. 따라서:

- S3 버킷 자체는 Terraform 외부에서 수동 생성/관리
- `s3_bucket_name` 변수만 Terraform에 선언해 CloudFront origin 연결에 활용
- 버킷 정책, OAC 설정은 CloudFront 구성 시 함께 적용

---

## 4. RDS 구성 및 엔드포인트 안정성

**Q. 콘솔에서 생성한 RDS를 Terraform으로 가져오려면?**

1. `main.tf`에 `aws_db_instance` 리소스 코드 작성
2. `terraform import aws_db_instance.main todolist-db` 로 state에 편입
3. `terraform plan`으로 실제 설정과 코드의 차이 확인
4. diff가 없어질 때까지 코드 수정 반복

import 후 발견한 주요 설정 차이:
- `backup_retention_period`: 코드 7 → 실제 1 (수정)
- `copy_tags_to_snapshot`: 코드 없음 → 실제 true (추가)
- `publicly_accessible`: 코드 false → 실제 true (수정)

**Q. RDS 엔드포인트는 destroy/apply 반복하면 바뀌나? EIP 같은 고정 개념이 있나?**

RDS는 EIP 같은 별도 고정 메커니즘 없이도 `identifier`가 같으면 엔드포인트가 불변이다. `cdqpv9e2voky`는 개별 인스턴스 ID가 아니라 계정+리전 수준의 식별자라, destroy 후 동일 identifier로 재생성하면 같은 엔드포인트가 나온다.

엔드포인트: `todolist-db.cdqpv9e2voky.ap-northeast-2.rds.amazonaws.com` → 앱 설정에 고정 가능

**Q. RDS 패스워드는 어떻게 관리하나?**

`terraform.tfvars`에 평문으로 저장하지 않고 환경변수로 주입:
```bash
export TF_VAR_db_password="패스워드"
terraform apply -auto-approve
```
`variables.tf`에 `sensitive = true` 선언으로 plan/apply 출력에서 마스킹.

---

## 5. EC2 + EIP 구성

**Q. EC2를 destroy/apply로 관리할 때 IP가 바뀌면 앱 설정을 매번 바꿔야 하나?**

EIP(탄력적 IP)를 미리 할당해두고 `aws_eip`와 `aws_eip_association`을 분리해 관리한다.

- `aws_eip` → `prevent_destroy = true` (영구 보유, EIP 할당 유지)
- `aws_eip_association` → EC2와 EIP를 연결하는 리소스 (destroy 대상)

EC2 destroy 시: association만 해제 → EIP는 할당된 상태로 유지 (미사용 EIP 요금 발생하지만 미미)
EC2 apply 시: 새 인스턴스에 동일 EIP 재연결 → IP 변경 없음

```bash
# EC2 삭제 (EIP는 유지)
terraform destroy -target=aws_eip_association.main -target=aws_instance.main -auto-approve

# EC2 재생성 후 EIP 재연결
terraform apply -target=aws_instance.main -target=aws_eip_association.main -auto-approve
```

**Q. 보안 그룹 description이 코드와 실제가 달라서 plan에서 replace가 뜨는데?**

AWS는 보안 그룹 description을 생성 후 수정할 수 없다(immutable). 콘솔에서 생성 시 자동으로 타임스탬프가 붙은 description이 저장됐는데, 코드의 description과 달라 Terraform이 destroy+create(replace)를 시도한 것.

해결: `lifecycle { ignore_changes = [description] }` 추가로 description 변경 무시.

---

## 6. 변수화 및 보일러플레이트

**Q. 이 프로젝트를 다음 프로젝트 시작할 때도 쓰려면 어떻게 해야 하나?**

프로젝트별로 달라지는 값을 모두 변수화하고, `terraform.tfvars.example`을 템플릿으로 활용.

반드시 수정할 변수:
| 변수 | 설명 |
|------|------|
| `project_name` | 리소스 이름 prefix (예: myblog) |
| `ec2_key_name` | AWS 콘솔에서 생성한 키 페어 이름 |
| `ssh_allowed_cidr` | 내 공인 IP/32 |
| `s3_bucket_name` | S3 버킷 이름 |

동일 AWS 계정이면 기본값 그대로 써도 되는 변수:
- `vpc_id`, `rds_security_group_id`, `iam_role_arn`, `ec2_ami`

`db_major_version` 같은 파생 값은 `locals`로 자동 계산:
```hcl
locals {
  db_major_version = split(".", var.db_engine_version)[0]  # "18.3" → "18"
}
```

---

## 7. Amplify 문서화

**Q. Amplify를 Terraform 생명주기에 넣어야 할까?**

넣지 않는 게 맞다. 이유:
- destroy 시 GitHub 레포지토리 연동이 끊기고 빌드 설정이 초기화됨
- 사용량 기반 과금이라 유휴 비용 없음 (destroy할 이유가 없음)
- 재설정이 번거로움

대신 `docs/aws-services/amplify.md`에 앱 ID, 환경변수, 빌드 설정 등을 기록해 수동 관리 시 참고할 수 있도록 문서화.

**Amplify 환경 변수:**

| 변수명 | 값 | 설명 |
|--------|-----|------|
| `NEXT_PUBLIC_API_URL` | `https://dzcf5t1ap5pg3.cloudfront.net/api` | 백엔드 API 엔드포인트 |
| `NEXT_PUBLIC_GOOGLE_CLIENT_ID` | `469542265119-5oe3fmaqj8p1rjk5nm5096fgnsp8t17e.apps.googleusercontent.com` | Google OAuth 클라이언트 ID |

> `NEXT_PUBLIC_API_URL`은 CloudFront 도메인 변경 시 함께 업데이트 필요.

---

## 8. CloudFront 구성

**Q. Amplify 프론트엔드(HTTPS)에서 EC2 백엔드(HTTP)를 직접 호출하면 안 되나?**

안 된다. HTTPS 페이지에서 HTTP 리소스를 로드하면 브라우저가 Mixed Content 오류로 차단한다. CloudFront를 EC2 앞에 붙여 HTTPS 엔드포인트를 제공하는 것이 해결책.

CloudFront가 HTTPS를 종료하고 EC2로는 HTTP로 전달하는 구조:
```
Amplify (HTTPS) → CloudFront (HTTPS 종료) → EC2 (HTTP:8080)
```

**Q. CloudFront에 WAF를 기본 무료 보호만 붙이면 의미 있나?**

CloudFront 생성 마법사에서 제공하는 "기본 보호(Basic protections)"는 OWASP 상위 공격 패턴 차단과 Amazon 위협 인텔리전스 IP 차단이 포함되어 있어 완전히 없는 것보다는 낫다.

그러나 핵심 기능인 SQL Injection 전용 룰셋, Rate Limiting, L7 DDoS 방어는 유료 플랜에만 있다. WAF Web ACL 자체가 월 $5 기본 과금이 발생하므로, 포트폴리오 프로젝트에서는 **WAF 없이 CloudFront만 사용**하는 것이 더 합리적이다.

콘솔에서 CloudFront 생성 시 WAF가 자동으로 붙었는데(`CreatedByCloudFront`), Terraform apply 시 제거해 월 $5 절감.

**Q. CloudFront를 destroy해도 괜찮나?**

CloudFront는 `prevent_destroy = true`로 보호. 이유:
- 생성/삭제에 15분+ 소요
- 도메인이 바뀌면 Amplify 환경변수 `NEXT_PUBLIC_API_URL`도 함께 변경해야 함
- 사용량 기반 과금으로 유휴 비용 없음

**Q. 콘솔에서 생성한 CloudFront와 코드의 주요 차이는?**

| 항목 | 콘솔 생성 시 | Terraform 코드 |
|------|-------------|---------------|
| EC2 포트 | 80 (기본값) | **8080** (앱 실제 포트) |
| Price Class | PriceClass_All | **PriceClass_200** (한국 포함, 저렴) |
| WAF | 자동 연결됨 | **없음** ($5/월 절감) |
| Cache Policy (EC2) | CachingDisabled (managed) | CachingDisabled (managed) 동일 |
| Cache Policy (S3) | CachingOptimized | CachingOptimized 동일 |

---

## 9. S3 Origin + OAC 구성

**Q. CloudFront에 S3 origin을 추가할 때 어떤 정보가 필요한가?**

- S3 버킷 이름: `todolist-dev-rerun1129`
- 경로 패턴: `todos/*` (첨부파일), `editor/*` (에디터 이미지)
- OAC ID: `E1U6N248Y73X1I` (CloudFront → 보안 → 원본 액세스 제어에서 확인)

OAC(Origin Access Control)는 S3 버킷을 퍼블릭 공개 없이 CloudFront에서만 접근하게 하는 메커니즘. OAC ID는 S3 버킷 정책의 ARN에 포함되지 않고 별도 콘솔 메뉴에서 확인해야 한다.

**Q. 경로 패턴이 2개면 CloudFront 동작(Behavior)도 2개 만들어야 하나?**

맞다. 경로 패턴 하나당 동작 하나. `todos/*`와 `editor/*` 각각 동작을 만들고 S3 origin을 지정.

**Q. S3 퍼블릭 액세스를 차단하니 기존에 보이던 이미지가 403이 뜨는데?**

코드 레벨에서 URL을 교체해야 한다. 기존에 S3 직접 URL(`todolist-dev-rerun1129.s3.ap-northeast-2.amazonaws.com/todos/...`)로 서빙하던 것을 CloudFront URL(`dzcf5t1ap5pg3.cloudfront.net/todos/...`)로 변경 필요.

수정 위치: 파일 업로드 후 URL을 DB에 저장하거나 응답으로 내려주는 백엔드 코드, 또는 URL을 직접 조합하는 프론트엔드 코드.

**S3 버킷 정책 (CloudFront OAC 전용 접근):**
```json
{
    "Version": "2012-10-17",
    "Statement": [{
        "Effect": "Allow",
        "Principal": { "Service": "cloudfront.amazonaws.com" },
        "Action": "s3:GetObject",
        "Resource": "arn:aws:s3:::todolist-dev-rerun1129/*",
        "Condition": {
            "StringEquals": {
                "AWS:SourceArn": "arn:aws:cloudfront::740636428516:distribution/EQ5G8LNMI2WQL"
            }
        }
    }]
}
```

---

## 10. 최종 아키텍처

```
GitHub (Next.js)
  → Amplify (HTTPS)
      master.d3iprkvplk2uky.amplifyapp.com
          ↓ API 호출
      CloudFront (HTTPS)
          dzcf5t1ap5pg3.cloudfront.net
              ├─ todos/*   → S3 (todolist-dev-rerun1129, OAC)
              ├─ editor/*  → S3 (todolist-dev-rerun1129, OAC)
              └─ *         → EC2 (HTTP:8080, 52.78.180.13)
                                → Spring Boot
                                      → RDS PostgreSQL
                                          todolist-db.cdqpv9e2voky...
```

---

## 11. Terraform 관리 범위 요약

| 서비스 | 관리 방식 | destroy 가능 |
|--------|----------|-------------|
| EC2, 보안그룹 | Terraform | O |
| RDS | Terraform | O (비용 절감용) |
| EIP | Terraform | X (`prevent_destroy`) |
| CloudFront, OAC | Terraform | X (`prevent_destroy`) |
| S3 | 수동 (콘솔) | — |
| Amplify | 수동 (콘솔) | — |
| IAM User/Role | 수동 (콘솔, 1회) | — |

---

## 12. 주요 리소스 정보

| 리소스 | 값 |
|--------|-----|
| ~~EC2 EIP~~ | ~~52.78.180.13~~ → **release됨** (새로 발급 후 import 필요) |
| RDS 엔드포인트 | todolist-db.cdqpv9e2voky.ap-northeast-2.rds.amazonaws.com |
| CloudFront 도메인 | https://dzcf5t1ap5pg3.cloudfront.net |
| CloudFront Distribution ID | EQ5G8LNMI2WQL |
| CloudFront OAC ID | E1U6N248Y73X1I |
| S3 버킷 | todolist-dev-rerun1129 |
| Terraform state | s3://todolist-dev-rerun1129/tfstate/dev/terraform.tfstate |
| Amplify 앱 ID | d3iprkvplk2uky |
| Amplify URL | https://master.d3iprkvplk2uky.amplifyapp.com |
| IAM Role ARN | arn:aws:iam::740636428516:role/portfolio-terraform-role |

---

## 13. 현재 인프라 상태 (세션 종료 시점 기준)

**실행 중 (과금 중):**
- CloudFront (EQ5G8LNMI2WQL) — `prevent_destroy`, 월 ~$0-1
- S3 버킷 (todolist-dev-rerun1129) — 월 ~$0

**내려간 상태 (코드는 유지):**
- EC2 — destroy됨
- RDS — destroy됨
- EIP — release됨 (다음 EC2 올릴 때 새로 발급 필요)

**월 예상 과금:** ~$0-1 (CloudFront + S3만)

---

## 14. EIP release 결정

**Q. EIP를 계속 들고 있어야 할까?**

2024년 2월부터 AWS는 미연결 EIP에도 $0.005/시간 과금 → 월 $3.60. EC2가 내려가 있는 동안 불필요한 비용이므로 release.

**다음에 EC2를 올릴 때:**
1. AWS 콘솔에서 EIP 새로 발급 → 할당 ID(`eipalloc-xxx`) 확인
2. `terraform import aws_eip.main <eipalloc-xxx>`
3. `terraform apply -target=aws_cloudfront_distribution.main -auto-approve` — CloudFront origin IP 업데이트
4. EC2에 EIP 연결: `terraform apply -target=aws_instance.main -target=aws_eip_association.main -auto-approve`

> CloudFront origin이 `aws_eip.main.public_ip`를 참조하므로, EIP가 바뀌면 CloudFront apply도 함께 필요.

---

## 15. S3 백엔드 설정 (멀티 컴퓨터 작업)

**Q. 여러 컴퓨터에서 동일한 Terraform 프로젝트를 작업하려면?**

`terraform.tfstate`가 로컬에만 있으면 다른 컴퓨터에서 state를 알 수 없어 apply/destroy가 불가능하다. S3 백엔드를 설정해 state를 S3에 저장하면 어느 컴퓨터에서든 동일한 state로 작업 가능.

설정된 백엔드 (`environments/dev/main.tf`):
```hcl
backend "s3" {
  bucket  = "todolist-dev-rerun1129"
  key     = "tfstate/dev/terraform.tfstate"
  region  = "ap-northeast-2"
  profile = "portfolio"

  assume_role = {
    role_arn = "arn:aws:iam::740636428516:role/portfolio-terraform-role"
  }
}
```

**다른 컴퓨터에서 시작하는 방법:**
```bash
git clone https://github.com/rerun1129/portfolio-infra.git
cd portfolio-infra/environments/dev

# ~/.aws/credentials에 [portfolio] 프로파일 설정 필요
terraform init   # S3에서 최신 state 자동으로 가져옴
terraform plan   # 현재 상태 확인
```

**Q. terraform.tfstate가 git에 올라가지 않나?**

`.gitignore`에 `*.tfstate`가 등록되어 있어 git에는 올라가지 않는다. S3가 유일한 저장소.

---

## 16. 다른 컴퓨터에서 이어 작업 시 체크리스트

새 컴퓨터에서 이 프로젝트를 처음 사용할 때:

- [ ] `git clone https://github.com/rerun1129/portfolio-infra.git`
- [ ] `~/.aws/credentials`에 `[portfolio]` 프로파일 추가 (Access Key는 별도 보관)
- [ ] `cd environments/dev && terraform init` — S3 state 연결 확인
- [ ] `terraform plan` — 현재 AWS 상태와 코드 일치 여부 확인
- [ ] EC2를 올릴 예정이면 EIP 신규 발급 후 Claude에게 알릴 것 (import + CloudFront 업데이트 필요)

---

## 17. 과금 분석 및 비용 최적화 (2026-04-13)

**Q. 어제(4/12) $0.45 과금 내역 분석**

| 서비스 | 금액 | 원인 |
|--------|------|------|
| RDS | $0.18 | db.t3.small 3시간 ($0.084) + gp2 스토리지 prorated ($0.09) |
| Amplify | $0.10 | 빌드 시간 약 10분 (푸시 3~5회 × 2~3분) |
| EC2 | $0.06 | 인스턴스 실행 시간 |
| VPC | $0.06 | NAT Gateway 또는 데이터 전송 |
| Tax | $0.05 | |

**핵심 인사이트:**
- RDS 비용은 인스턴스 타입이 지배적. 스토리지 크기(20GB→5GB) 조정은 3시간 기준 $0.009 절감으로 효과 미미
- Amplify는 빌드(푸시)할 때만 과금. 서비스 존재만으로는 스토리지 비용 월 $0.002/앱 수준
- EC2/RDS 내려간 현재 상태로 4월 말까지 유지 시 월 예상액 ~$0.50

**Q. RDS 인스턴스 타입 확인 필요**

현재 db.t3.small($0.056/hr)로 추정. db.t3.micro($0.028/hr)로 낮추면 세션당 비용 절반.

---

## 18. AWS Budgets 알람 설정

**기존 예산 `My Non-Commercial Project` 수정:**
- 예산 금액: $50 → **$5**
- 알람 1: 실제 비용 60% ($3) 초과 시 → `a01021719359@gmail.com`
- 알람 2: 예측 비용 100% ($5) 초과 시 → `a01021719359@gmail.com`

월별 예산 + 2단계 알람 구조가 일별 예산보다 효과적. 일별은 작업 세션마다 오탐 발생.

---

## 19. Route 53 도메인 및 nextcraft 인프라

**도메인:** `nextcraft.click` (Route 53, $3/년, .click TLD)
- 호스팅 영역: $0.50/월 고정 과금 → 유지 필수 (삭제 시 NS 변경됨)
- 상태: 등록 진행 중 (완료 후 Amplify 커스텀 도메인 연결 예정)

**Amplify 커스텀 도메인 연결 절차 (도메인 등록 완료 후):**
1. Amplify 콘솔 → 앱(`d3iprkvplk2uky`) → App settings → Custom domains
2. `nextcraft.click` 추가
3. Route 53 레코드 자동 생성 확인 (같은 계정이면 자동)
4. SSL 인증서 자동 발급 확인

---

## 20. S3 퍼블릭 버킷 생성 (nextcraft-portfolio-assets)

**목적:** nextcraft 포트폴리오용 `projects.json` 퍼블릭 호스팅

| 항목 | 값 |
|------|-----|
| 버킷 이름 | `nextcraft-portfolio-assets` |
| 리전 | `ap-northeast-2` |
| 퍼블릭 URL | `https://nextcraft-portfolio-assets.s3.ap-northeast-2.amazonaws.com/projects.json` |

**Bucket Policy** (projects.json 단일 파일만 퍼블릭, 보안):
```json
{
  "Version": "2012-10-17",
  "Statement": [{
    "Effect": "Allow",
    "Principal": "*",
    "Action": "s3:GetObject",
    "Resource": "arn:aws:s3:::nextcraft-portfolio-assets/projects.json"
  }]
}
```

**CORS:**
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

`/*` 대신 특정 파일만 허용하는 정책으로 민감 데이터 실수 업로드 방지.

---

## 21. 현재 인프라 상태 (2026-04-13 기준)

**실행 중 (과금 중):**
- CloudFront (EQ5G8LNMI2WQL) — `prevent_destroy`, 월 ~$0-1
- S3 버킷 (todolist-dev-rerun1129) — Terraform state 보관, 월 ~$0
- S3 버킷 (nextcraft-portfolio-assets) — 신규 생성, 월 ~$0
- Route 53 호스팅 영역 (nextcraft.click) — $0.50/월
- Amplify (d3iprkvplk2uky) — 빌드 시만 과금

**내려간 상태 (코드는 유지):**
- EC2 — destroy됨
- RDS — destroy됨
- EIP — release됨

**월 예상 과금:** ~$0.50-1.00 (Route 53 호스팅 영역 $0.50 추가됨)

---

## 22. 주요 리소스 정보 (업데이트)

| 리소스 | 값 |
|--------|-----|
| EC2 EIP | release됨 (새로 발급 후 import 필요) |
| RDS 엔드포인트 | todolist-db.cdqpv9e2voky.ap-northeast-2.rds.amazonaws.com |
| CloudFront 도메인 | https://dzcf5t1ap5pg3.cloudfront.net |
| CloudFront Distribution ID | EQ5G8LNMI2WQL |
| CloudFront OAC ID | E1U6N248Y73X1I |
| S3 버킷 (todolist) | todolist-dev-rerun1129 |
| S3 버킷 (nextcraft) | nextcraft-portfolio-assets |
| Terraform state | s3://todolist-dev-rerun1129/tfstate/dev/terraform.tfstate |
| Amplify 앱 ID | d3iprkvplk2uky |
| Amplify URL | https://master.d3iprkvplk2uky.amplifyapp.com |
| IAM Role ARN | arn:aws:iam::740636428516:role/portfolio-terraform-role |
| 도메인 | nextcraft.click (Route 53, 등록 진행 중) |
