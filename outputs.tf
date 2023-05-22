output "relay_distribution_domain_name" {
  description = "The domain name of the relay CloudFront distribution."
  value       = aws_cloudfront_distribution.fullstory_relay.domain_name
}
