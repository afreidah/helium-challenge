<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.waf](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_wafv2_web_acl.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl) | resource |
| [aws_wafv2_web_acl_logging_configuration.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/wafv2_web_acl_logging_configuration) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_blocked_countries"></a> [blocked\_countries](#input\_blocked\_countries) | List of country codes to block using ISO 3166-1 alpha-2 format | `list(string)` | `[]` | no |
| <a name="input_cloudwatch_metrics_enabled"></a> [cloudwatch\_metrics\_enabled](#input\_cloudwatch\_metrics\_enabled) | Enable CloudWatch metrics for monitoring WAF activity | `bool` | `true` | no |
| <a name="input_default_action"></a> [default\_action](#input\_default\_action) | Default action for requests that do not match any rules (allow or block) | `string` | `"allow"` | no |
| <a name="input_enable_aws_managed_rules"></a> [enable\_aws\_managed\_rules](#input\_enable\_aws\_managed\_rules) | Enable AWS managed rule groups for common vulnerabilities and bad inputs | `bool` | `true` | no |
| <a name="input_enable_geo_blocking"></a> [enable\_geo\_blocking](#input\_enable\_geo\_blocking) | Enable geographic blocking based on country codes | `bool` | `false` | no |
| <a name="input_enable_ip_reputation"></a> [enable\_ip\_reputation](#input\_enable\_ip\_reputation) | Enable AWS IP reputation lists to block known malicious sources | `bool` | `true` | no |
| <a name="input_enable_logging"></a> [enable\_logging](#input\_enable\_logging) | Enable WAF logging to CloudWatch | `bool` | `true` | no |
| <a name="input_enable_rate_limiting"></a> [enable\_rate\_limiting](#input\_enable\_rate\_limiting) | Enable rate limiting to prevent request flooding | `bool` | `true` | no |
| <a name="input_log_kms_key_id"></a> [log\_kms\_key\_id](#input\_log\_kms\_key\_id) | KMS key ID for encrypting WAF logs | `string` | `null` | no |
| <a name="input_log_retention_days"></a> [log\_retention\_days](#input\_log\_retention\_days) | Number of days to retain WAF logs | `number` | `90` | no |
| <a name="input_name"></a> [name](#input\_name) | Name of the WAF WebACL | `string` | n/a | yes |
| <a name="input_rate_limit"></a> [rate\_limit](#input\_rate\_limit) | Maximum number of requests allowed per 5 minutes from a single IP | `number` | `2000` | no |
| <a name="input_redacted_fields"></a> [redacted\_fields](#input\_redacted\_fields) | List of header names to redact from logs (e.g., authorization, cookie) | `list(string)` | <pre>[<br/>  "authorization",<br/>  "cookie"<br/>]</pre> | no |
| <a name="input_sampled_requests_enabled"></a> [sampled\_requests\_enabled](#input\_sampled\_requests\_enabled) | Enable sampling of requests for analysis and troubleshooting | `bool` | `true` | no |
| <a name="input_scope"></a> [scope](#input\_scope) | Scope of the WAF (REGIONAL for ALB/API Gateway, CLOUDFRONT for CloudFront) | `string` | `"REGIONAL"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to the WAF WebACL | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_web_acl_arn"></a> [web\_acl\_arn](#output\_web\_acl\_arn) | ARN of the WAF WebACL |
| <a name="output_web_acl_capacity"></a> [web\_acl\_capacity](#output\_web\_acl\_capacity) | Capacity units used by the WebACL |
| <a name="output_web_acl_id"></a> [web\_acl\_id](#output\_web\_acl\_id) | ID of the WAF WebACL |
| <a name="output_web_acl_name"></a> [web\_acl\_name](#output\_web\_acl\_name) | Name of the WAF WebACL |
<!-- END_TF_DOCS -->