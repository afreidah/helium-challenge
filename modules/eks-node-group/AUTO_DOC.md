<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
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
| [aws_eks_node_group.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_node_group) | resource |
| [aws_iam_instance_profile.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_instance_profile) | resource |
| [aws_iam_role.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.node_AmazonEC2ContainerRegistryReadOnly](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_AmazonEKSWorkerNodePolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_AmazonEKS_CNI_Policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_AmazonSSMManagedInstanceCore](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.node_CloudWatchAgentServerPolicy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_launch_template.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/launch_template) | resource |
| [aws_security_group.node](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.node_egress_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_egress_dns_tcp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_egress_dns_udp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_egress_http](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_egress_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_egress_ntp](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_ingress_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_ingress_cluster_https](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.node_ingress_self](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_ssm_parameter.eks_ami](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_security_group_ids"></a> [additional\_security\_group\_ids](#input\_additional\_security\_group\_ids) | Additional security group IDs to attach to nodes | `list(string)` | `[]` | no |
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for worker nodes (uses EKS-optimized AMI if not specified) | `string` | `null` | no |
| <a name="input_bootstrap_extra_args"></a> [bootstrap\_extra\_args](#input\_bootstrap\_extra\_args) | Additional arguments for the bootstrap script | `string` | `""` | no |
| <a name="input_capacity_type"></a> [capacity\_type](#input\_capacity\_type) | Type of capacity (ON\_DEMAND or SPOT) | `string` | `"ON_DEMAND"` | no |
| <a name="input_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#input\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data for the cluster | `string` | n/a | yes |
| <a name="input_cluster_endpoint"></a> [cluster\_endpoint](#input\_cluster\_endpoint) | Endpoint for EKS control plane | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_security_group_id"></a> [cluster\_security\_group\_id](#input\_cluster\_security\_group\_id) | Security group ID of the EKS cluster | `string` | n/a | yes |
| <a name="input_cluster_version"></a> [cluster\_version](#input\_cluster\_version) | Kubernetes version of the cluster | `string` | n/a | yes |
| <a name="input_desired_size"></a> [desired\_size](#input\_desired\_size) | Desired number of nodes | `number` | `2` | no |
| <a name="input_disk_encryption_key_id"></a> [disk\_encryption\_key\_id](#input\_disk\_encryption\_key\_id) | KMS key ID for EBS encryption | `string` | `null` | no |
| <a name="input_disk_size"></a> [disk\_size](#input\_disk\_size) | Disk size in GB for worker nodes | `number` | `20` | no |
| <a name="input_disk_type"></a> [disk\_type](#input\_disk\_type) | EBS volume type | `string` | `"gp3"` | no |
| <a name="input_enable_cloudwatch_agent"></a> [enable\_cloudwatch\_agent](#input\_enable\_cloudwatch\_agent) | Enable CloudWatch agent on nodes | `bool` | `false` | no |
| <a name="input_enable_detailed_monitoring"></a> [enable\_detailed\_monitoring](#input\_enable\_detailed\_monitoring) | Enable detailed monitoring (1-minute intervals) | `bool` | `false` | no |
| <a name="input_enable_ssm_access"></a> [enable\_ssm\_access](#input\_enable\_ssm\_access) | Enable SSM Session Manager access to nodes | `bool` | `true` | no |
| <a name="input_instance_types"></a> [instance\_types](#input\_instance\_types) | List of instance types for the node group | `list(string)` | <pre>[<br/>  "t3.medium"<br/>]</pre> | no |
| <a name="input_labels"></a> [labels](#input\_labels) | Key-value map of Kubernetes labels | `map(string)` | `{}` | no |
| <a name="input_max_size"></a> [max\_size](#input\_max\_size) | Maximum number of nodes | `number` | `10` | no |
| <a name="input_max_unavailable_percentage"></a> [max\_unavailable\_percentage](#input\_max\_unavailable\_percentage) | Max percentage of nodes unavailable during update | `number` | `33` | no |
| <a name="input_min_size"></a> [min\_size](#input\_min\_size) | Minimum number of nodes | `number` | `1` | no |
| <a name="input_node_group_name"></a> [node\_group\_name](#input\_node\_group\_name) | Name of the node group | `string` | n/a | yes |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the node group | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_taints"></a> [taints](#input\_taints) | List of Kubernetes taints to apply to nodes | <pre>list(object({<br/>    key    = string<br/>    value  = string<br/>    effect = string<br/>  }))</pre> | `[]` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where nodes will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_iam_instance_profile_arn"></a> [iam\_instance\_profile\_arn](#output\_iam\_instance\_profile\_arn) | ARN of the IAM instance profile |
| <a name="output_iam_instance_profile_name"></a> [iam\_instance\_profile\_name](#output\_iam\_instance\_profile\_name) | Name of the IAM instance profile |
| <a name="output_iam_role_arn"></a> [iam\_role\_arn](#output\_iam\_role\_arn) | ARN of the IAM role for nodes |
| <a name="output_iam_role_name"></a> [iam\_role\_name](#output\_iam\_role\_name) | Name of the IAM role for nodes |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | ID of the launch template |
| <a name="output_launch_template_latest_version"></a> [launch\_template\_latest\_version](#output\_launch\_template\_latest\_version) | Latest version of the launch template |
| <a name="output_node_group_arn"></a> [node\_group\_arn](#output\_node\_group\_arn) | Amazon Resource Name (ARN) of the EKS Node Group |
| <a name="output_node_group_id"></a> [node\_group\_id](#output\_node\_group\_id) | EKS node group ID |
| <a name="output_node_group_resources"></a> [node\_group\_resources](#output\_node\_group\_resources) | Resources associated with the node group |
| <a name="output_node_group_status"></a> [node\_group\_status](#output\_node\_group\_status) | Status of the EKS node group |
| <a name="output_security_group_arn"></a> [security\_group\_arn](#output\_security\_group\_arn) | ARN of the security group for the node group |
| <a name="output_security_group_id"></a> [security\_group\_id](#output\_security\_group\_id) | Security group ID for the node group |
<!-- END_TF_DOCS -->