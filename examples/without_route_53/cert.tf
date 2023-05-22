resource "aws_acm_certificate" "fullstory_relay" {
  domain_name       = "fsrelay.your-company.com"
  validation_method = "DNS"
}

output "relay_cert_dns_validation" {
  description = "The information required to create a DNS validation record."
  value       = {
    for dvo in aws_acm_certificate.fullstory_relay.domain_validation_options : dvo.domain_name => {
      name   = dvo.resource_record_name
      record = dvo.resource_record_value
      type   = dvo.resource_record_type
    }
  }
}