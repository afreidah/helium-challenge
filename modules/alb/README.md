<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 6.18.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_lb.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_config"></a> [alb\_config](#input\_alb\_config) | ALB configuration object from root.hcl | <pre>object({<br/>    name_suffix                      = string<br/>    load_balancer_type               = string<br/>    internal                         = bool<br/>    enable_deletion_protection       = bool<br/>    enable_cross_zone_load_balancing = bool<br/>    enable_http2                     = bool<br/>    enable_waf_fail_open             = bool<br/>    desync_mitigation_mode           = string<br/>    drop_invalid_header_fields       = bool<br/>    preserve_host_header             = bool<br/>    enable_xff_client_port           = bool<br/>    xff_header_processing_mode       = string<br/>    idle_timeout                     = number<br/>    subnet_ids                       = list(string)<br/>    security_group_ids               = list(string)<br/>    access_logs = object({<br/>      enabled = bool<br/>      bucket  = optional(string)<br/>      prefix  = optional(string)<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name for resource identification | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., production, staging) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alb_arn"></a> [alb\_arn](#output\_alb\_arn) | ARN of the Application Load Balancer |
| <a name="output_alb_arn_suffix"></a> [alb\_arn\_suffix](#output\_alb\_arn\_suffix) | ARN suffix for use with CloudWatch metrics |
| <a name="output_alb_dns_name"></a> [alb\_dns\_name](#output\_alb\_dns\_name) | DNS name of the Application Load Balancer |
| <a name="output_alb_id"></a> [alb\_id](#output\_alb\_id) | ID of the Application Load Balancer |
| <a name="output_alb_name"></a> [alb\_name](#output\_alb\_name) | Name of the Application Load Balancer |
| <a name="output_alb_zone_id"></a> [alb\_zone\_id](#output\_alb\_zone\_id) | Route53 zone ID for the Application Load Balancer |
<!-- END_TF_DOCS -->