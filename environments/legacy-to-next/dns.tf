# ============================================================
# 기존 Route53 호스팅 영역(nextcraft.click) — 조회만(신규 생성 안 함).
# todolist 루트 레코드는 미변경. legacy-to-next는 서브도메인만 추가.
# ============================================================

data "aws_route53_zone" "main" {
  name         = var.domain_name
  private_zone = false
}

# api.<domain> → CloudFront (persistent — EC2 lifecycle와 무관)
resource "aws_route53_record" "api" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.api_domain
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.api.domain_name
    zone_id                = aws_cloudfront_distribution.api.hosted_zone_id
    evaluate_target_health = false
  }
}

# l2n-origin.<domain> → EC2 공인 IP (EC2와 함께 생성/파기). CloudFront origin이 이 호스트명을 사용.
resource "aws_route53_record" "origin" {
  zone_id = data.aws_route53_zone.main.zone_id
  name    = local.origin_host
  type    = "A"
  ttl     = 60
  records = [aws_instance.main.public_ip]
}

# app.<domain> 레코드는 Amplify 도메인 연결(amplify.tf)이 자동 생성하므로 여기서 만들지 않는다.
