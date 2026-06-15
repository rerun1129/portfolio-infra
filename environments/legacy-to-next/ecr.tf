# ============================================================
# ECR — 백엔드 5종 이미지(게이트웨이·fms·admin·bms·pms). FE는 Amplify(ECR 불요).
# 사이클 간 이미지·repo 유지(spin-up은 pull). lifecycle: 최근 3개만 보관.
# ============================================================

locals {
  ecr_repos = ["gateway", "fms", "admin", "bms", "pms"]
}

resource "aws_ecr_repository" "this" {
  for_each     = toset(local.ecr_repos)
  name         = "${var.project_name}/${each.key}"
  force_delete = true

  image_scanning_configuration {
    scan_on_push = false
  }
}

resource "aws_ecr_lifecycle_policy" "this" {
  # 정적 repo 집합으로 키잉 — aws_ecr_repository.this 직접 참조는 첫 plan 에서
  # "known only after apply" 오류. 키는 정적, repository 이름만 apply-time 참조.
  for_each   = toset(local.ecr_repos)
  repository = aws_ecr_repository.this[each.key].name

  policy = jsonencode({
    rules = [{
      rulePriority = 1
      description  = "keep last 3"
      selection = {
        tagStatus   = "any"
        countType   = "imageCountMoreThan"
        countNumber = 3
      }
      action = { type = "expire" }
    }]
  })
}
