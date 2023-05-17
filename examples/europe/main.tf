module "fullstory_relay" {
  source      = "fullstorydev/fullstory-cloud-relay/aws"
  relay_fqdn  = "fsrelay.your-company.com"
  target_fqdn = "eu1.fullstory.com"
}
