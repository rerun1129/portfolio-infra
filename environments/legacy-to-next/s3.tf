# ============================================================
# EDMS 첨부 버킷 — 기존 수동 생성분(legacy-to-next, ap-northeast-2, SSE-S3)을
# IaC로 import 한다. 재생성/삭제가 아니라 상태로 흡수하는 것이 목적.
#
# import 절차 (toolchain+자격증명 있는 환경에서):
#   terraform import aws_s3_bucket.edms legacy-to-next
#   terraform import aws_s3_bucket_server_side_encryption_configuration.edms legacy-to-next
#   terraform import aws_s3_bucket_public_access_block.edms legacy-to-next   # PAB 미설정 시 생략 후 신규 생성
#   terraform plan   # zero-diff 될 때까지 아래 속성을 실제값에 맞춰 조정(versioning/tags 등)
#
# 주의: public_access_block 이 기존에 없으면 import가 실패하므로, 그 경우 import를 생략하고
#       apply 로 신규 적용(=의도된 보안 강화). 첫 plan 결과를 반드시 검토할 것.
# ============================================================

resource "aws_s3_bucket" "edms" {
  bucket = var.s3_bucket_name

  lifecycle {
    prevent_destroy = true # teardown 시에도 첨부 데이터 보존 — 절대 삭제 금지
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "edms" {
  bucket = aws_s3_bucket.edms.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256" # SSE-S3 (KMS 아님 — 실측 확인됨)
    }
  }
}

resource "aws_s3_bucket_public_access_block" "edms" {
  bucket = aws_s3_bucket.edms.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
