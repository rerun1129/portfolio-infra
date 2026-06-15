# ============================================================
# RDS PostgreSQL — 관리형 단일 데이터스토어(앱 17.x).
# 비용 최소: db.t3.micro · gp3 20GB(최소) · single-AZ · 백업 0 · private.
# 마스터 비번은 manage_master_user_password=true 로 Secrets Manager 자동관리
# (평문이 state/tfvars에 남지 않음 — 과거 유출 이력 대응). 앱은 별도 'fms' 역할로 접속.
# OFF 시 destroy + 재시드 운영이라 identifier는 고정해 엔드포인트를 안정화한다.
# ============================================================

resource "aws_db_instance" "main" {
  identifier     = "${var.project_name}-db"
  engine         = "postgres"
  engine_version = var.db_engine_version
  instance_class = var.db_instance_class

  allocated_storage     = var.db_allocated_storage
  max_allocated_storage = 0 # 오토스케일 비활성(고정 20GB)
  storage_type          = "gp3"
  storage_encrypted     = true

  username                     = "postgres"
  manage_master_user_password  = true # AWS Secrets Manager 자동관리(평문 미보유)
  db_name                      = null # user-data가 'fms' DB/스키마/역할 생성

  db_subnet_group_name   = "default-${var.vpc_id}"
  vpc_security_group_ids = [aws_security_group.rds.id]

  multi_az            = false
  publicly_accessible = false

  backup_retention_period = 0
  deletion_protection     = false
  skip_final_snapshot     = true

  performance_insights_enabled = false
  monitoring_interval          = 0

  apply_immediately = true
}
