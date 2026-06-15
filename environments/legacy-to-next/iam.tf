# ============================================================
# EC2 instance role — S3(edms RW + deploy read) · Secrets(app + RDS master) ·
# ECR pull · SSM. 정적 키 대신 인스턴스 역할로 접근(보안 개선).
# ============================================================

resource "aws_iam_role" "ec2" {
  name = "${var.project_name}-ec2-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role_policy" "ec2_inline" {
  name = "${var.project_name}-ec2-inline"
  role = aws_iam_role.ec2.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "S3List"
        Effect   = "Allow"
        Action   = ["s3:ListBucket"]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}"
        Condition = {
          StringLike = { "s3:prefix" = ["${var.s3_key_prefix}/*", "${var.s3_deploy_prefix}/*"] }
        }
      },
      {
        Sid      = "S3EdmsRW"
        Effect   = "Allow"
        Action   = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject"]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_key_prefix}/*"
      },
      {
        Sid      = "S3DeployRead"
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = "arn:aws:s3:::${var.s3_bucket_name}/${var.s3_deploy_prefix}/*"
      },
      {
        # app 시크릿 + RDS 관리형 마스터 시크릿(rds!* 접두사)을 와일드카드로 허용.
        # RDS 리소스 attr을 직접 참조하지 않아 EC2/RDS targeted destroy 시 IAM이 연쇄되지 않음.
        Sid    = "SecretsRead"
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          aws_secretsmanager_secret.app.arn,
          "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:rds!*",
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ec2_ecr" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_iam_role_policy_attachment" "ec2_ssm" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_instance_profile" "ec2" {
  name = "${var.project_name}-ec2-profile"
  role = aws_iam_role.ec2.name
}

# ============================================================
# GitHub Actions OIDC → ECR push (opt-in: var.enable_cicd_oidc).
# 계정에 token.actions.githubusercontent.com provider가 이미 있으면 false 유지
# (provider는 계정당 1개). 기본 false → 홈 PC에서 수동 push로 동작.
# ============================================================

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.enable_cicd_oidc ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1", "1c58a3a8518e8759bf075b76b750d4f2df264fcd"]
}

resource "aws_iam_role" "gha_ecr_push" {
  count = var.enable_cicd_oidc ? 1 : 0
  name  = "${var.project_name}-gha-ecr-push"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github[0].arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.github_repo}:*" }
      }
    }]
  })
}

resource "aws_iam_role_policy" "gha_ecr_push" {
  count = var.enable_cicd_oidc ? 1 : 0
  name  = "${var.project_name}-gha-ecr-push"
  role  = aws_iam_role.gha_ecr_push[0].id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "EcrAuth"
        Effect   = "Allow"
        Action   = ["ecr:GetAuthorizationToken"]
        Resource = "*"
      },
      {
        Sid    = "EcrPush"
        Effect = "Allow"
        Action = [
          "ecr:BatchCheckLayerAvailability",
          "ecr:InitiateLayerUpload",
          "ecr:UploadLayerPart",
          "ecr:CompleteLayerUpload",
          "ecr:PutImage",
          "ecr:BatchGetImage",
        ]
        Resource = [for r in aws_ecr_repository.this : r.arn]
      },
      # CD: 이미지 push 후 가동 중 EC2에 SSM으로 재배포(docker compose pull && up -d).
      {
        Sid      = "Ec2Describe"
        Effect   = "Allow"
        Action   = ["ec2:DescribeInstances"]
        Resource = "*"
      },
      {
        # SendCommand는 Project 태그가 일치하는 인스턴스에만 허용(최소권한).
        Sid      = "SsmSendToTaggedInstance"
        Effect   = "Allow"
        Action   = ["ssm:SendCommand"]
        Resource = "arn:aws:ec2:${var.aws_region}:${data.aws_caller_identity.current.account_id}:instance/*"
        Condition = {
          StringEquals = { "ssm:resourceTag/Project" = var.project_name }
        }
      },
      {
        Sid      = "SsmSendDocument"
        Effect   = "Allow"
        Action   = ["ssm:SendCommand"]
        Resource = "arn:aws:ssm:${var.aws_region}::document/AWS-RunShellScript"
      },
      {
        Sid      = "SsmReadInvocation"
        Effect   = "Allow"
        Action   = ["ssm:GetCommandInvocation"]
        Resource = "*"
      }
    ]
  })
}

# ============================================================
# GitHub Actions OIDC → Terraform 인프라 라이프사이클 (infra repo).
# OIDC provider는 gha_ecr_push와 공유. 트러스트=infra repo(var.infra_github_repo).
# terraform이 직접 이 역할로 동작(CI에선 profile/assume 비활성) → 광범위 권한 필요.
# portfolio-terraform-role은 이 IaC 밖 외부 관리 역할이라 그것의 트러스트를 코드로 못 고침 →
# 자족적 OIDC 역할을 여기서 정의(state 버킷 접근 포함, AdministratorAccess).
# ============================================================

resource "aws_iam_role" "gha_infra" {
  count = var.enable_cicd_oidc ? 1 : 0
  name  = "${var.project_name}-gha-infra"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Federated = aws_iam_openid_connect_provider.github[0].arn }
      Action    = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = { "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com" }
        StringLike   = { "token.actions.githubusercontent.com:sub" = "repo:${var.infra_github_repo}:*" }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "gha_infra_admin" {
  count      = var.enable_cicd_oidc ? 1 : 0
  role       = aws_iam_role.gha_infra[0].name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}
