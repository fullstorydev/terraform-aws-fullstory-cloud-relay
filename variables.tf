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
  description = "(optional) The Route 53 zone name for placing the DNS CNAME record. If omitted, a value for `acm_certificate_arn` must be provided. Defaults to null."
  default     = null
}

variable "acm_certificate_arn" {
  type        = string
  description = "(optional) The ARN of the ACM certificate to be used for the relay. If omitted, a value for `route53_zone_name` must be provided. Defaults to null."
  default     = null
}
