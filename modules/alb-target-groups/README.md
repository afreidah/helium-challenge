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
| [aws_lb_target_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_target_group) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name for resource identification | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., production, staging) | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created | `string` | n/a | yes |
| <a name="input_target_groups"></a> [target\_groups](#input\_target\_groups) | Map of target group configurations | <pre>map(object({<br/>    port                 = number<br/>    protocol             = string<br/>    target_type          = string<br/>    deregistration_delay = number<br/>    health_check = object({<br/>      enabled             = bool<br/>      healthy_threshold   = number<br/>      interval            = number<br/>      matcher             = string<br/>      path                = string<br/>      port                = string<br/>      protocol            = string<br/>      timeout             = number<br/>      unhealthy_threshold = number<br/>    })<br/>    stickiness = optional(object({<br/>      enabled         = bool<br/>      type            = string<br/>      cookie_duration = number<br/>    }))<br/>  }))</pre> | `{}` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where target groups will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_target_group_arn_suffixes"></a> [target\_group\_arn\_suffixes](#output\_target\_group\_arn\_suffixes) | Map of target group names to their ARN suffixes for CloudWatch metrics |
| <a name="output_target_group_arns"></a> [target\_group\_arns](#output\_target\_group\_arns) | Map of target group names to their ARNs |
| <a name="output_target_group_ids"></a> [target\_group\_ids](#output\_target\_group\_ids) | Map of target group names to their IDs |
| <a name="output_target_group_names"></a> [target\_group\_names](#output\_target\_group\_names) | Map of target group keys to their actual names |
<!-- END_TF_DOCS -->