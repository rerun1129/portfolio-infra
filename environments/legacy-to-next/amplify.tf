# ============================================================
# Amplify — Next.js(standalone/SSR) 프론트엔드. app.<domain> 도메인 연결.
# var.amplify_oauth_token(GitHub PAT) 제공 시에만 생성(미제공=수동 콘솔 연결).
# todolist Amplify 앱(d3iprkvplk2uky)은 미간섭(별도 신규 앱).
# build env NEXT_PUBLIC_*는 빌드타임 인라인 → 게이트웨이 단일 base URL만 주입.
# ============================================================

locals {
  amplify_enabled = var.amplify_oauth_token != ""
}

resource "aws_amplify_app" "fe" {
  count        = local.amplify_enabled ? 1 : 0
  name         = "${var.project_name}-fe"
  repository   = var.amplify_repo_url
  access_token = var.amplify_oauth_token
  platform     = "WEB_COMPUTE"

  environment_variables = {
    NEXT_PUBLIC_API_BASE_URL  = "https://${local.api_domain}"
    NEXT_PUBLIC_USE_MOCK      = "false"
    AMPLIFY_MONOREPO_APP_ROOT = "front-end"
  }

  build_spec = <<-YAML
    version: 1
    applications:
      - appRoot: front-end
        frontend:
          phases:
            preBuild:
              commands:
                - npm ci
            build:
              commands:
                - npm run build
          artifacts:
            baseDirectory: .next
            files:
              - '**/*'
          cache:
            paths:
              - node_modules/**/*
  YAML

  lifecycle {
    ignore_changes = [access_token]
  }
}

resource "aws_amplify_branch" "master" {
  count             = local.amplify_enabled ? 1 : 0
  app_id            = aws_amplify_app.fe[0].id
  branch_name       = var.amplify_branch
  framework         = "Next.js - SSR"
  stage             = "PRODUCTION"
  enable_auto_build = true
}

resource "aws_amplify_domain_association" "fe" {
  count       = local.amplify_enabled ? 1 : 0
  app_id      = aws_amplify_app.fe[0].id
  domain_name = var.domain_name

  sub_domain {
    branch_name = aws_amplify_branch.master[0].branch_name
    prefix      = var.app_subdomain
  }
}
