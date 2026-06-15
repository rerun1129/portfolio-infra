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
        Sid      = "SecretsRead"
        Effect   = "Allow"
        Action   = ["secretsmanager:GetSecretValue"]
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
      }
    ]
  })
}
