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
| [aws_kms_alias.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_alias_name"></a> [alias\_name](#input\_alias\_name) | KMS key alias name (without 'alias/' prefix) | `string` | `null` | no |
| <a name="input_deletion_window_in_days"></a> [deletion\_window\_in\_days](#input\_deletion\_window\_in\_days) | Duration in days before key deletion | `number` | `30` | no |
| <a name="input_description"></a> [description](#input\_description) | Description of the KMS key | `string` | n/a | yes |
| <a name="input_enable_key_rotation"></a> [enable\_key\_rotation](#input\_enable\_key\_rotation) | Enable automatic key rotation | `bool` | `true` | no |
| <a name="input_policy"></a> [policy](#input\_policy) | KMS key policy (JSON) | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags for the KMS key | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_alias_arn"></a> [alias\_arn](#output\_alias\_arn) | KMS alias ARN |
| <a name="output_alias_name"></a> [alias\_name](#output\_alias\_name) | KMS alias name |
| <a name="output_key_arn"></a> [key\_arn](#output\_key\_arn) | KMS key ARN |
| <a name="output_key_id"></a> [key\_id](#output\_key\_id) | KMS key ID |
<!-- END_TF_DOCS -->