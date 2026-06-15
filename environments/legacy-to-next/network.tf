# ============================================================
# 보안 그룹 — EC2(게이트웨이 공개) / RDS(EC2에서만)
# CloudFront origin-facing prefix list로 8084를 CloudFront에만 개방한다.
# ============================================================

data "aws_ec2_managed_prefix_list" "cloudfront" {
  name = "com.amazonaws.global.cloudfront.origin-facing"
}

resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg"
  description = "${var.project_name} EC2 (gateway via CloudFront)"
  vpc_id      = var.vpc_id

  # 게이트웨이(8084) — CloudFront origin-facing 대역에서만 인입
  ingress {
    description     = "gateway from CloudFront"
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    prefix_list_ids = [data.aws_ec2_managed_prefix_list.cloudfront.id]
  }

  # SSH — ssh_allowed_cidr 지정 시에만 개방(미지정=SSM Session Manager 사용)
  dynamic "ingress" {
    for_each = var.ssh_allowed_cidr == "" ? [] : [var.ssh_allowed_cidr]
    content {
      description = "ssh"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = [ingress.value]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [description]
  }
}

resource "aws_security_group" "rds" {
  name        = "${var.project_name}-rds-sg"
  description = "${var.project_name} RDS (from EC2 only)"
  vpc_id      = var.vpc_id

  ingress {
    description     = "postgres from EC2"
    from_port       = 5432
    to_port         = 5432
    protocol        = "tcp"
    security_groups = [aws_security_group.ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  lifecycle {
    ignore_changes = [description]
  }
}
