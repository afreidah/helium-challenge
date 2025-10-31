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
| [aws_iam_policy.read_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_secretsmanager_secret.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_rotation.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_rotation) | resource |
| [aws_secretsmanager_secret_version.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_create_read_policy"></a> [create\_read\_policy](#input\_create\_read\_policy) | Create IAM policy for reading secrets | `bool` | `false` | no |
| <a name="input_kms_key_arn"></a> [kms\_key\_arn](#input\_kms\_key\_arn) | KMS key ARN for IAM policy permissions (required if create\_read\_policy is true) | `string` | `null` | no |
| <a name="input_policy_name_prefix"></a> [policy\_name\_prefix](#input\_policy\_name\_prefix) | Prefix for IAM policy name | `string` | `"app"` | no |
| <a name="input_secrets"></a> [secrets](#input\_secrets) | Map of secrets to create with keys as secret names and values containing secret configuration | <pre>map(object({<br/>    description             = optional(string)<br/>    secret_string           = string<br/>    kms_key_id              = optional(string)<br/>    recovery_window_in_days = optional(number, 30)<br/>    rotation_lambda_arn     = optional(string)<br/>    rotation_days           = optional(number)<br/>  }))</pre> | `{}` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to all resources | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_read_policy_arn"></a> [read\_policy\_arn](#output\_read\_policy\_arn) | ARN of the IAM read policy (if created) |
| <a name="output_read_policy_name"></a> [read\_policy\_name](#output\_read\_policy\_name) | Name of the IAM read policy (if created) |
| <a name="output_secret_arns"></a> [secret\_arns](#output\_secret\_arns) | Map of secret ARNs |
| <a name="output_secret_ids"></a> [secret\_ids](#output\_secret\_ids) | Map of secret IDs |
| <a name="output_secret_versions"></a> [secret\_versions](#output\_secret\_versions) | Map of secret version IDs |
<!-- END_TF_DOCS -->