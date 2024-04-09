locals {
  module_name = "fullstory-cloud-relay/aws"

  version                    = try(compact([for m in jsondecode(file("${path.module}/../modules.json"))["Modules"] : length(regexall(".${local.module_name}.*", m["Source"])) > 0 ? m["Version"] : ""])[0], "unreleased")
  create_dns_record_and_cert = tobool(var.route53_zone_name != null)
  endpoints = {
    edge : "edge.${var.target_fqdn}",
    rs : "rs.${var.target_fqdn}",
    services : "services.fullstory.com"
  }
  response_headers_policy_name = "Managed-CORS-with-preflight-and-SecurityHeadersPolicy"
  cache_policy_name_disabled   = "Managed-CachingDisabled"
  cache_policy_name_optimized  = "Managed-CachingOptimized"
}

data "aws_cloudfront_cache_policy" "caching_disabled" {
  name = local.cache_policy_name_disabled
}

data "aws_cloudfront_cache_policy" "caching_optimized" {
  name = local.cache_policy_name_optimized
}

data "aws_cloudfront_response_headers_policy" "cors" {
  name = local.response_headers_policy_name
}

data "aws_route53_zone" "fullstory_relay" {
  count = local.create_dns_record_and_cert ? 1 : 0
  name  = var.route53_zone_name
}

data "aws_arn" "fullstory_relay" {
  # Used to validate a user-supplied ARN before usage in the CloudFront distribution
  count = local.create_dns_record_and_cert ? 0 : 1
  arn   = var.acm_certificate_arn
}

######## Certificate Resources ########

resource "aws_acm_certificate" "fullstory_relay" {
  count             = local.create_dns_record_and_cert ? 1 : 0
  domain_name       = var.relay_fqdn
  validation_method = "DNS"

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route53_record" "fullstory_relay_dns_validation" {
  for_each = local.create_dns_record_and_cert ? {
    for dvo in aws_acm_certificate.fullstory_relay[0].domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  } : {}

  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = data.aws_route53_zone.fullstory_relay[0].zone_id
}

resource "aws_acm_certificate_validation" "fullstory_relay" {
  count                   = local.create_dns_record_and_cert ? 1 : 0
  certificate_arn         = aws_acm_certificate.fullstory_relay[0].arn
  validation_record_fqdns = [for record in aws_route53_record.fullstory_relay_dns_validation : record.fqdn]
}

######## CloudFront Resources ########

resource "aws_cloudfront_origin_request_policy" "fullstory_relay" {
  name    = var.cloudfront_origin_request_policy_name

  comment = "Fullstory Relay"
  headers_config {
    header_behavior = "allExcept"
    headers {
      items = ["host"]
    }
  }
  cookies_config {
    cookie_behavior = "none"
  }
  query_strings_config {
    query_string_behavior = "all"
  }
  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_cloudfront_distribution" "fullstory_relay" {
  depends_on      = [aws_acm_certificate_validation.fullstory_relay]
  enabled         = true
  is_ipv6_enabled = true
  aliases         = [var.relay_fqdn]

  dynamic "origin" {
    for_each = local.endpoints
    content {
      custom_header {
        name  = "X-Relay-Origin"
        value = "AWS"
      }
      custom_header {
        name  = "X-Relay-Version"
        value = local.version
      }
      domain_name = origin.value
      origin_id   = origin.key
      custom_origin_config {
        http_port                = 80
        https_port               = 443
        origin_protocol_policy   = "https-only"
        origin_ssl_protocols     = ["TLSv1.2"]
        origin_read_timeout      = 30
        origin_keepalive_timeout = 5
      }
      connection_attempts = 3
      connection_timeout  = 10
    }
  }

  default_cache_behavior {
    allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.fullstory_relay.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
    target_origin_id           = "rs"
    viewer_protocol_policy     = "redirect-to-https"
  }

  # Cache behavior with precedence 0
  ordered_cache_behavior {
    path_pattern               = "/s/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.fullstory_relay.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
    target_origin_id           = "edge"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern               = "/datalayer/*"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_optimized.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.fullstory_relay.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
    target_origin_id           = "edge"
    compress                   = true
    viewer_protocol_policy     = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern               = "/rec/bundle"
    allowed_methods            = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.fullstory_relay.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
    target_origin_id           = "rs"
    viewer_protocol_policy     = "redirect-to-https"
  }

  ordered_cache_behavior {
    path_pattern               = "/echo"
    allowed_methods            = ["GET", "HEAD"]
    cached_methods             = ["GET", "HEAD"]
    cache_policy_id            = data.aws_cloudfront_cache_policy.caching_disabled.id
    origin_request_policy_id   = aws_cloudfront_origin_request_policy.fullstory_relay.id
    response_headers_policy_id = data.aws_cloudfront_response_headers_policy.cors.id
    target_origin_id           = "services"
    viewer_protocol_policy     = "redirect-to-https"
  }

  price_class = "PriceClass_All"

  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  viewer_certificate {
    acm_certificate_arn      = local.create_dns_record_and_cert ? aws_acm_certificate.fullstory_relay[0].arn : data.aws_arn.fullstory_relay[0].arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2021"
  }
}

######## Route53 Resources ########

resource "aws_route53_record" "fullstory_relay" {
  count = local.create_dns_record_and_cert ? 1 : 0

  zone_id = data.aws_route53_zone.fullstory_relay[0].zone_id
  name    = var.relay_fqdn
  type    = "A"

  alias {
    name                   = aws_cloudfront_distribution.fullstory_relay.domain_name
    zone_id                = aws_cloudfront_distribution.fullstory_relay.hosted_zone_id
    evaluate_target_health = true
  }
}
