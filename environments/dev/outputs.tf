# 환경별 리소스 outputs를 여기에 정의합니다.

output "cloudfront_domain" {
  description = "CloudFront 도메인 (프론트엔드 API_BASE_URL에 사용)"
  value       = "https://${aws_cloudfront_distribution.main.domain_name}"
}
