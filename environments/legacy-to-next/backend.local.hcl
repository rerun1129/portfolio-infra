# 로컬 terraform 실행용 backend 인증 (민감정보 아님 — 기존 main.tf에 있던 값을 분리한 것).
# 사용:  terraform init -backend-config=backend.local.hcl
#   (이미 init된 디렉토리라면 backend 설정 변경 감지로 -reconfigure 필요:
#    terraform init -reconfigure -backend-config=backend.local.hcl)
# CI(GitHub Actions OIDC)는 이 파일 없이  terraform init  만 실행(환경 자격 사용).
profile = "portfolio"

assume_role = {
  role_arn = "arn:aws:iam::740636428516:role/portfolio-terraform-role"
}
