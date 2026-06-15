# ============================================================
# 앱 시크릿 — 단일 JSON(DB_PASSWORD=fms 역할 / JWT_SECRET / INTERNAL_GATEWAY_KEY).
# special=false: 영숫자만 → 쉘/.env/SQL 인용에서 안전.
# RDS 마스터(postgres) 비번은 RDS가 별도 관리(rds.tf manage_master_user_password).
# recovery_window_in_days=0: destroy 시 즉시 삭제(재생성 충돌 방지).
# ============================================================

resource "random_password" "db" {
  length  = 24
  special = false
}

resource "random_password" "jwt" {
  length  = 48
  special = false
}

resource "random_password" "internal_gw" {
  length  = 32
  special = false
}

resource "aws_secretsmanager_secret" "app" {
  name                    = "${var.project_name}/dev/app"
  recovery_window_in_days = 0
}

resource "aws_secretsmanager_secret_version" "app" {
  secret_id = aws_secretsmanager_secret.app.id
  secret_string = jsonencode({
    DB_PASSWORD          = random_password.db.result
    JWT_SECRET           = random_password.jwt.result
    INTERNAL_GATEWAY_KEY = random_password.internal_gw.result
  })
}
