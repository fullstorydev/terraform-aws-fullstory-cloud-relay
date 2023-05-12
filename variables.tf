variable "relay_fqdn" {
  type        = string
  description = "The fully qualified domain name for the relay. Example: `fsrelay.your-company.com`."
}

variable "target_fqdn" {
  type        = string
  description = "(optional) The fully qualified domain name that the relay targets. Defaults to `fullstory.com`."
  default     = "fullstory.com"
}

variable "route53_zone_name" {
  type        = string
  description = "(optional) The Route 53 zone name for placing the DNS CNAME record. Defaults to null."
  default     = null
}
