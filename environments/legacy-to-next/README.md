# environments/legacy-to-next — 홈 PC 실행 런북

legacy-to-next(6컨테이너 물류 SaaS) AWS 배포. **todolist(`environments/dev/`)와 병존** — todolist 리소스·state·코드 미변경.

## 아키텍처
`https://app.<도메인>` (Amplify, Next.js SSR) → API → `https://api.<도메인>` (CloudFront → EC2 게이트웨이 8084)
→ fms/admin/bms/pms. 데이터: RDS PostgreSQL 17(관리형) + Mongo·Redis(EC2 compose 자체호스팅).
- EC2 **t3.large(8GB)** · 컨테이너별 mem_limit+작은 힙(5 JVM+Mongo+Redis 공존)
- RDS **db.t3.micro · gp3 20GB · private · 마스터비번 Secrets Manager 자동관리**
- **EIP 없음**(자동 공인IP, CloudFront origin은 `l2n-origin.<도메인>` 호스트명으로 디커플링)
- 세션 변동비 ≈ EC2+RDS만(1시간 ≈ $0.15) / OFF 고정 floor ≈ $1/mo

## 사전 요구사항 (실행 PC)
- Terraform ≥ 1.5, AWS CLI v2, Docker, `psql`(PostgreSQL 15+ 클라이언트)
- `~/.aws` 에 `portfolio` 프로필(assume `portfolio-terraform-role` 가능)
- (Amplify 자동연결 시) GitHub PAT → `export TF_VAR_amplify_oauth_token=<PAT>`

> ⚠️ **실행 PC 분리 가능**: 시드 추출(sample_export.sql)은 **2M 소스 DB가 있는 PC**에서 실행한다
> (현재 그 데이터는 *작업 PC*의 docker 볼륨 `legacy-to-next_postgres_data`에 있음 — `docker compose up -d postgres`로 기동).
> terraform 실행 PC와 달라도 무방 — 산출 TSV는 **S3로 전달**(git 아님)되고 EC2가 S3에서 적재한다.
> 추출 PC엔 업로드용 **aws CLI + portfolio 자격증명**만 있으면 됨(terraform 불요). 둘 다 없으면 sample_data/를
> 파일 복사로 terraform PC에 옮겨 거기서 `aws s3 cp` 해도 됨.

## 0. 최초 1회 셋업
```bash
cd environments/legacy-to-next
terraform init

# (a) 기존 S3 버킷 import — 재생성 아님
terraform import aws_s3_bucket.edms legacy-to-next
terraform import aws_s3_bucket_server_side_encryption_configuration.edms legacy-to-next
terraform import aws_s3_bucket_public_access_block.edms legacy-to-next   # PAB 없으면 생략(아래 apply가 신규 생성)
terraform plan   # zero-diff(또는 의도된 PAB 추가)만 나오는지 확인

# (b) ECR 먼저 생성(이미지 push 대상)
terraform apply -target=aws_ecr_repository.this

# (c) 백엔드 5종 이미지 빌드·push (앱 repo 루트에서) — DEPLOY.md 참조
#     또는 var.enable_cicd_oidc=true 로 apply 후 GitHub Actions Deploy 사용

# (d) 시드 추출(앱 repo 루트, 로컬 DB 기동 상태) → 배포 번들 업로드
cd <앱repo>            # legacy-to-next
mkdir -p sample_data
psql "postgresql://fms:fms_local@localhost:5432/fms" -v ON_ERROR_STOP=1 -f seed/sample_export.sql   # 행수 NOTICE 확인
aws s3 cp docker-compose.aws.yml s3://legacy-to-next/deploy/docker-compose.aws.yml --profile portfolio
aws s3 cp seed/sample_load.sql   s3://legacy-to-next/deploy/seed/sample_load.sql   --profile portfolio
aws s3 cp --recursive sample_data/ s3://legacy-to-next/deploy/seed/sample_data/   --profile portfolio
#  (합성 폴백을 쓰려면 위 2줄 대신: aws s3 cp seed/demo_1k.sql s3://legacy-to-next/deploy/seed/demo_1k.sql)

# (e) 전체 생성
cd environments/legacy-to-next
export TF_VAR_amplify_oauth_token=<github PAT>   # 선택(미설정 시 Amplify 생성 안 함→콘솔 수동 연결)
terraform apply
```

## 1. 접속 (apply 후 ~3–5분: user-data 부트스트랩 + ACM/CloudFront 전파)
- **프론트엔드(화면)**: `https://app.<도메인>` (예: `https://app.nextcraft.click`)
- **API/게이트웨이**: `https://api.<도메인>` (예: `https://api.nextcraft.click/health`)
- **로그인 계정**(admin Flyway 시드): `fms`/`fms12345` · `admin`/`admin1234` · `bms`/`bms12345` · `pms`/`pms`
- 해석 경로: `app.` → Amplify, `api.` → CloudFront → `l2n-origin.<도메인>`(=EC2 공인IP) → 게이트웨이.
- 부트 로그 확인(문제 시): SSM Session Manager 또는 SSH → `sudo tail -f /var/log/user-data.log`
- `terraform output` 으로 api_url·app_url·rds_endpoint·ec2_public_dns 확인.

## 2. 재기동(spin-up) / 종료(tear-down)
```bash
# 재기동 (이미지·번들 이미 있음; 코드 바뀌었으면 (c)(d) 먼저 갱신)
terraform apply

# 종료 — EC2+RDS+origin 레코드만 제거(플랫폼·S3·CloudFront·ACM·Amplify·ECR 유지)
terraform destroy -target=aws_instance.main -target=aws_db_instance.main -target=aws_route53_record.origin
```
종료 후 idle: Route53 존(기존)+Secrets($0.40)+ECR(~$0.3)+S3 ≈ **$1/mo 미만**, EC2/RDS=$0.

## 3. 트러블슈팅
- `engine_version 17.x` 미지원 오류 → `terraform apply -var db_engine_version=<유효버전>` (오류 메시지에 목록).
- `db_subnet_group "default-vpc-..."` 없음 → 콘솔에서 default 서브넷그룹명 확인 후 rds.tf 수정(또는 var 추가).
- ACM 검증 지연 → 보통 수 분. `aws_acm_certificate_validation` 에서 대기(정상).
- OIDC `provider already exists` → 계정에 이미 GitHub OIDC 있음 → `enable_cicd_oidc=false`(기본) 유지, 수동 push.
- Amplify 도메인 미연결 → PAT 미설정. `TF_VAR_amplify_oauth_token` 설정 후 재apply(또는 콘솔 연결).
- 시드 실패(WARN in user-data.log) → 컬럼/제약 불일치. `sample_export.sql` 행수 확인 후 재추출·재업로드, EC2 재생성(`terraform taint aws_instance.main && terraform apply`).

## 4. Phase 진행 상태 (전부 작성 완료 — 실행은 이 PC)
- [x] A. scaffold + S3 import 준비
- [x] B. EC2 t3.large · RDS 17 private · SG 2종
- [x] C. Secrets(단일 JSON) · EC2 instance role · ECR 5 · OIDC(opt-in)
- [x] D. ACM(us-east-1) · CloudFront(api.) · Amplify(app.) · Route53 레코드
- [x] E. compose override · 참조 슬라이스 샘플러(export/load) · 합성 폴백 · deploy.yml · user-data
