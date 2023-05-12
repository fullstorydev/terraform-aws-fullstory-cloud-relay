module "fullstory_relay" {
  source     = "fullstorydev/fullstory-cloud-relay/aws"
  relay_fqdn = "fsrelay.your-company.com"
}

output "relay_distribution_domain_name" {
  value = module.fullstory_relay.relay_distribution_domain_name
}

output "relay_cert_dns_validation" {
  value = module.fullstory_relay.relay_cert_dns_validation
}