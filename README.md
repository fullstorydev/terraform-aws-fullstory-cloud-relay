<a href="https://fullstory.com"><img src="https://d36ubspakw5kl4.cloudfront.net/fullstory.png" width="600"></a>

# terraform-aws-fullstory-cloud-relay

[![GitHub release](https://img.shields.io/github/release/fullstorydev/terraform-aws-fullstory-cloud-relay.svg)](https://github.com/fullstorydev/terraform-aws-fullstory-cloud-relay/releases/)


This module creates a relay that allows you to route all captured FullStory traffic
from your users’ browser directly through your own domain. More information on the philosophy and 
script configuration can be found in this KB article (TODO: add link).

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.59.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_relay_fqdn"></a> [relay\_fqdn](#input\_relay\_fqdn) | The fully qualified domain name for the relay. Example: `fsrelay.your-company.com`. | `string` | n/a | yes |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | (optional) The Route 53 zone name for placing the DNS CNAME record. Defaults to null. | `string` | `null` | no |
| <a name="input_target_fqdn"></a> [target\_fqdn](#input\_target\_fqdn) | (optional) The fully qualified domain name that the relay targets. Defaults to `fullstory.com`. | `string` | `"fullstory.com"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_relay_cert_dns_validation"></a> [relay\_cert\_dns\_validation](#output\_relay\_cert\_dns\_validation) | The information required to create a DNS validation record. |
| <a name="output_relay_distribution_domain_name"></a> [relay\_distribution\_domain\_name](#output\_relay\_distribution\_domain\_name) | The domain name of the relay CloudFront distribution. |

## Usage

### With Route 53 Record Creation

This module will automatically create the DNS records if a value for `route53_zone_name` is provided in reference to an existing Route 53 zone within hte same AWS account.

```hcl
module "fullstory_relay" {
  source            = "fullstorydev/fullstory-cloud-relay/aws"
  relay_fqdn        = "fsrelay.your-company.com"
  route53_zone_name = "your-company.com."
}
```

> :warning: **Note:** CloudFront Distributions can take 10-15 minutes to become active after creation.

### Without Route 53 Record Creation

By default, the module will not create a DNS record in Route 53. An example of which is below.

```hcl
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
```

Once the resources have been successfully created, the CNAME of the CloudFront distribution and the DNS validation record information can be extracted from the Terraform state using the command below.

```bash
terraform output relay_ip_address
```

If the above command does not work, ensure that the two `output` blocks are present as shown in the example above.

Next, create a `CNAME` DNS record that routes the `relay_fqdn` to the `relay_distribution_domain_name` found in the previous command.

Finally, create a DNS validation `CNAME` record that routes the `relay_cert_dns_validation.<relay_fqdn>.name` to the `relay_cert_dns_validation.<relay_fqdn>.record` value.

Once the DNS record has been created, the SSL certificate can take up to 15 minutes to become active. The status can be checked using the command below.

```bash
aws acm list-certificates
```

### European Realm Target

```hcl
module "fullstory_relay" {
  source      = "fullstorydev/fullstory-cloud-relay/aws"
  relay_fqdn  = "fsrelay.your-company.com"
  target_fqdn = "eu1.fullstory.com"
}
```

### Validation
Once an instance of the FullStory Relay has been successfully created, the health endpoint at `https://<relay_fqdn>/healthz` should return a `200 OK`.

## Resources

| Name | Type |
|------|------|
| [aws_acm_certificate.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate) | resource |
| [aws_acm_certificate_validation.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acm_certificate_validation) | resource |
| [aws_cloudfront_distribution.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_distribution) | resource |
| [aws_cloudfront_origin_request_policy.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudfront_origin_request_policy) | resource |
| [aws_route53_record.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_route53_record.fullstory_relay_dns_validation](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [aws_cloudfront_cache_policy.caching_disabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_cache_policy.caching_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_response_headers_policy.cors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_route53_zone.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
<!-- END_TF_DOCS -->

## Troubleshooting
This module includes a troubleshooting endpoint that can be used to debug any communications issues. The endpoint can be found out `https://<relay_fqdn>/echo` and returns the headers of the request.

## Contributing
See [CONTRIBUTING.md](https://github.com/fullstorydev/terraform-aws-fullstory-cloud-relay/blob/main/.github/CONTRIBUTING.md) for best practices and instructions on setting up your dev environment.
