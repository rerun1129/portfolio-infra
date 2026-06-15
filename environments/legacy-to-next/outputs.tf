# ============================================================
# Outputs
# ============================================================

output "s3_edms_bucket" {
  description = "EDMS 첨부 버킷"
  value       = aws_s3_bucket.edms.id
}

output "route53_zone_id" {
  description = "공유 Route53 호스팅 영역 ID"
  value       = data.aws_route53_zone.main.zone_id
}

output "ec2_public_dns" {
  description = "EC2 공인 DNS (SSH/SSM 참고)"
  value       = aws_instance.main.public_dns
}

output "ec2_public_ip" {
  description = "EC2 공인 IP (origin 레코드 대상)"
  value       = aws_instance.main.public_ip
}

output "rds_endpoint" {
  description = "RDS 엔드포인트"
  value       = aws_db_instance.main.address
}

output "api_url" {
  description = "게이트웨이 공개 URL"
  value       = "https://${local.api_domain}"
}

output "app_url" {
  description = "프론트엔드 URL"
  value       = "https://${local.app_domain}"
}

output "cloudfront_domain" {
  description = "CloudFront 배포 도메인"
  value       = aws_cloudfront_distribution.api.domain_name
}

output "ecr_registry" {
  description = "ECR 레지스트리 (docker login 대상)"
  value       = local.ecr_registry
}

output "ecr_repo_urls" {
  description = "ECR 레포 URL 목록"
  value       = [for r in aws_ecr_repository.this : r.repository_url]
}

output "app_secret_arn" {
  description = "앱 시크릿 ARN"
  value       = aws_secretsmanager_secret.app.arn
}

output "amplify_default_domain" {
  description = "Amplify 기본 도메인 (토큰 제공 시)"
  value       = local.amplify_enabled ? aws_amplify_app.fe[0].default_domain : null
  # amplify_enabled 가 sensitive 한 var.amplify_oauth_token 에서 파생 → 출력도 sensitive 표시 필요.
  sensitive   = true
}
