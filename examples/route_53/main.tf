module "fullstory_relay" {
  source            = "fullstorydev/fullstory-cloud-relay/aws"
  relay_fqdn        = "fsrelay.your-company.com"
  route53_zone_name = "your-company.com."
}