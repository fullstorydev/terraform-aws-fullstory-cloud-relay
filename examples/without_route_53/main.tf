module "fullstory_relay" {
  source              = "fullstorydev/fullstory-cloud-relay/aws"
  relay_fqdn          = "fsrelay.your-company.com"
  acm_certificate_arn = aws_acm_certificate.fullstory_relay.arn
}

output "relay_distribution_domain_name" {
  value = module.fullstory_relay.relay_distribution_domain_name
}
