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
| [aws_lb_listener.http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener.https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener) | resource |
| [aws_lb_listener_rule.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/lb_listener_rule) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alb_arn"></a> [alb\_arn](#input\_alb\_arn) | ARN of the Application Load Balancer | `string` | n/a | yes |
| <a name="input_common_tags"></a> [common\_tags](#input\_common\_tags) | Common tags to apply to all resources | `map(string)` | `{}` | no |
| <a name="input_component"></a> [component](#input\_component) | Component name for resource identification | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Environment name (e.g., production, staging) | `string` | n/a | yes |
| <a name="input_listener_rules"></a> [listener\_rules](#input\_listener\_rules) | Map of listener rules for path-based and host-based routing | <pre>map(object({<br/>    listener_protocol = string<br/>    priority          = number<br/>    conditions = list(object({<br/>      type             = string<br/>      values           = list(string)<br/>      http_header_name = optional(string)<br/>    }))<br/>    action = object({<br/>      type             = string<br/>      target_group_arn = optional(string)<br/>      redirect         = optional(map(string))<br/>      fixed_response   = optional(map(string))<br/>    })<br/>  }))</pre> | `{}` | no |
| <a name="input_listeners"></a> [listeners](#input\_listeners) | Listener configurations for HTTP and HTTPS | <pre>object({<br/>    http = object({<br/>      enabled  = bool<br/>      port     = number<br/>      protocol = string<br/>      default_action = object({<br/>        type             = string<br/>        target_group_arn = optional(string)<br/>        redirect         = optional(map(string))<br/>        fixed_response   = optional(map(string))<br/>      })<br/>    })<br/>    https = object({<br/>      enabled         = bool<br/>      port            = number<br/>      protocol        = string<br/>      ssl_policy      = string<br/>      certificate_arn = optional(string)<br/>      default_action = object({<br/>        type             = string<br/>        target_group_arn = optional(string)<br/>        redirect         = optional(map(string))<br/>        fixed_response   = optional(map(string))<br/>      })<br/>    })<br/>  })</pre> | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_http_listener_arn"></a> [http\_listener\_arn](#output\_http\_listener\_arn) | ARN of the HTTP listener |
| <a name="output_https_listener_arn"></a> [https\_listener\_arn](#output\_https\_listener\_arn) | ARN of the HTTPS listener |
| <a name="output_listener_rule_arns"></a> [listener\_rule\_arns](#output\_listener\_rule\_arns) | Map of listener rule names to their ARNs |
| <a name="output_listener_rule_ids"></a> [listener\_rule\_ids](#output\_listener\_rule\_ids) | Map of listener rule names to their IDs |
<!-- END_TF_DOCS -->