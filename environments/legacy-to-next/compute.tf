# ============================================================
# EC2 — docker-compose 스택(게이트웨이+4 백엔드+Mongo+Redis) 단일 호스트.
# user-data가 부팅 시: RDS init(pgcrypto/role/schema) → secrets→.env → ECR pull
#   → compose up(순서·health) → 1k 데모 시드. 프론트엔드는 Amplify(여기 없음).
# ============================================================

data "aws_caller_identity" "current" {}

locals {
  ecr_registry = "${data.aws_caller_identity.current.account_id}.dkr.ecr.${var.aws_region}.amazonaws.com"
  app_domain   = "${var.app_subdomain}.${var.domain_name}"
  api_domain   = "${var.api_subdomain}.${var.domain_name}"
  origin_host  = "${var.origin_subdomain}.${var.domain_name}"
}

resource "aws_instance" "main" {
  ami                         = var.ec2_ami
  instance_type               = var.ec2_instance_type
  key_name                    = var.ec2_key_name
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2.name
  associate_public_ip_address = true

  credit_specification {
    cpu_credits = "unlimited"
  }

  root_block_device {
    volume_size = var.ec2_root_volume_size
    volume_type = "gp3"
    encrypted   = true
  }

  monitoring = false

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region            = var.aws_region
    ecr_registry          = local.ecr_registry
    app_secret_arn        = aws_secretsmanager_secret.app.arn
    rds_master_secret_arn = aws_db_instance.main.master_user_secret[0].secret_arn
    rds_endpoint          = aws_db_instance.main.address
    s3_bucket             = var.s3_bucket_name
    s3_deploy_prefix      = var.s3_deploy_prefix
    app_origin            = "https://${local.app_domain}"
  })

  user_data_replace_on_change = true

  tags = {
    Name = "${var.project_name}-server"
  }

  depends_on = [aws_db_instance.main]
}
