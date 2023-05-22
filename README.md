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
| <a name="input_acm_certificate_arn"></a> [acm\_certificate\_arn](#input\_acm\_certificate\_arn) | (optional) The ARN of the ACM certificate to be used for the relay. If omitted, a value for `route53_zone_name` must be provided. Defaults to null. | `string` | `null` | no |
| <a name="input_relay_fqdn"></a> [relay\_fqdn](#input\_relay\_fqdn) | The fully qualified domain name for the relay. Example: `fsrelay.your-company.com`. | `string` | n/a | yes |
| <a name="input_route53_zone_name"></a> [route53\_zone\_name](#input\_route53\_zone\_name) | (optional) The Route 53 zone name for placing the DNS CNAME record. If omitted, a value for `acm_certificate_arn` must be provided. Defaults to null. | `string` | `null` | no |
| <a name="input_target_fqdn"></a> [target\_fqdn](#input\_target\_fqdn) | (optional) The fully qualified domain name that the relay targets. Defaults to `fullstory.com`. | `string` | `"fullstory.com"` | no |

## Outputs

| Name | Description |
|------|-------------|
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

By default, the module will not create a DNS record in Route 53 or certificate in ACM.

A certificate must be created and validated before the relay can be created. This can be done manually or via Terraform (example below).

```hcl
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
```

Once the certificate is created, it must be validated before it can be used. The DNS validation information can be extracted from the Terraform state using the command below.

```bash
terraform output relay_cert_dns_validation
```

Create a DNS validation `CNAME` record that routes the `relay_cert_dns_validation.<relay_fqdn>.name` to the `relay_cert_dns_validation.<relay_fqdn>.record` value.
Once the DNS record has been created, the certificate can take up to 15 minutes to become active. The status can be checked using the command below.

```bash
aws acm list-certificates --query "CertificateSummaryList[?DomainName=='<relay_fqdn>'].Status"
```

Now that the certificate has been created and is active, the ARN can be passed into the module as seen below.

```hcl
module "fullstory_relay" {
  source              = "fullstorydev/fullstory-cloud-relay/aws"
  relay_fqdn          = "fsrelay.your-company.com"
  acm_certificate_arn = aws_acm_certificate.fullstory_relay.arn
}

output "relay_distribution_domain_name" {
  value = module.fullstory_relay.relay_distribution_domain_name
}
```

Once the resources have been successfully created, the final step is to create the CNAME of the CloudFront distribution which can be extracted from the Terraform state using the command below.

```bash
terraform output relay_distribution_domain_name
```

Create a `CNAME` DNS record that routes the `relay_fqdn` to the `relay_distribution_domain_name` found in the previous command.

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
| [aws_arn.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/arn) | data source |
| [aws_cloudfront_cache_policy.caching_disabled](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_cache_policy.caching_optimized](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_cache_policy) | data source |
| [aws_cloudfront_response_headers_policy.cors](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/cloudfront_response_headers_policy) | data source |
| [aws_route53_zone.fullstory_relay](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |
<!-- END_TF_DOCS -->

## Troubleshooting
This module includes a troubleshooting endpoint that can be used to debug any communications issues. The endpoint can be found out `https://<relay_fqdn>/echo` and returns the headers of the request.

## Contributing
See [CONTRIBUTING.md](https://github.com/fullstorydev/terraform-aws-fullstory-cloud-relay/blob/main/.github/CONTRIBUTING.md) for best practices and instructions on setting up your dev environment.
