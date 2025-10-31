<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.5.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 5.0 |
| <a name="requirement_kubernetes"></a> [kubernetes](#requirement\_kubernetes) | ~> 2.23 |
| <a name="requirement_tls"></a> [tls](#requirement\_tls) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.100.0 |
| <a name="provider_kubernetes"></a> [kubernetes](#provider\_kubernetes) | 2.38.0 |
| <a name="provider_tls"></a> [tls](#provider\_tls) | 4.1.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_eks_addon.coredns](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.kube_proxy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.pod_identity_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_addon.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_addon) | resource |
| [aws_eks_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_cluster) | resource |
| [aws_iam_openid_connect_provider.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_openid_connect_provider) | resource |
| [aws_iam_role.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cluster_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.cluster_vpc_resource_controller](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_iam_role_policy_attachment.vpc_cni](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_kms_alias.eks_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.eks_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_security_group.cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_security_group_rule.cluster_egress_to_internet](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [aws_security_group_rule.cluster_egress_to_nodes](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group_rule) | resource |
| [kubernetes_config_map_v1_data.aws_auth](https://registry.terraform.io/providers/hashicorp/kubernetes/latest/docs/resources/config_map_v1_data) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.vpc_cni_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [tls_certificate.cluster](https://registry.terraform.io/providers/hashicorp/tls/latest/docs/data-sources/certificate) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_aws_auth_roles"></a> [aws\_auth\_roles](#input\_aws\_auth\_roles) | Additional IAM roles to add to aws-auth ConfigMap | <pre>list(object({<br/>    rolearn  = string<br/>    username = string<br/>    groups   = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_aws_auth_users"></a> [aws\_auth\_users](#input\_aws\_auth\_users) | Additional IAM users to add to aws-auth ConfigMap | <pre>list(object({<br/>    userarn  = string<br/>    username = string<br/>    groups   = list(string)<br/>  }))</pre> | `[]` | no |
| <a name="input_cloudwatch_kms_key_id"></a> [cloudwatch\_kms\_key\_id](#input\_cloudwatch\_kms\_key\_id) | KMS key ID for CloudWatch log encryption | `string` | `null` | no |
| <a name="input_cloudwatch_retention_days"></a> [cloudwatch\_retention\_days](#input\_cloudwatch\_retention\_days) | Number of days to retain CloudWatch logs | `number` | `90` | no |
| <a name="input_cluster_encryption_key_arn"></a> [cluster\_encryption\_key\_arn](#input\_cluster\_encryption\_key\_arn) | ARN of KMS key for cluster encryption | `string` | n/a | yes |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | Name of the EKS cluster | `string` | n/a | yes |
| <a name="input_coredns_version"></a> [coredns\_version](#input\_coredns\_version) | Version of CoreDNS add-on | `string` | `null` | no |
| <a name="input_eks_authentication_mode"></a> [eks\_authentication\_mode](#input\_eks\_authentication\_mode) | Authentication mode for cluster access (API or API\_AND\_CONFIG\_MAP) | `string` | `"API_AND_CONFIG_MAP"` | no |
| <a name="input_eks_bootstrap_cluster_creator_admin_permissions"></a> [eks\_bootstrap\_cluster\_creator\_admin\_permissions](#input\_eks\_bootstrap\_cluster\_creator\_admin\_permissions) | Bootstrap cluster creator admin permissions (grants admin access to IAM principal creating the cluster) | `bool` | `true` | no |
| <a name="input_eks_enable_cluster_logging"></a> [eks\_enable\_cluster\_logging](#input\_eks\_enable\_cluster\_logging) | Enable cluster control plane logging to CloudWatch | `bool` | `true` | no |
| <a name="input_eks_enable_pod_identity_agent"></a> [eks\_enable\_pod\_identity\_agent](#input\_eks\_enable\_pod\_identity\_agent) | Enable EKS Pod Identity Agent add-on (recommended over IRSA) | `bool` | `true` | no |
| <a name="input_eks_encryption_config"></a> [eks\_encryption\_config](#input\_eks\_encryption\_config) | Encryption configuration for EKS cluster secrets using KMS | <pre>object({<br/>    resources   = list(string)<br/>    kms_key_arn = string<br/>  })</pre> | <pre>{<br/>  "kms_key_arn": null,<br/>  "resources": [<br/>    "secrets"<br/>  ]<br/>}</pre> | no |
| <a name="input_eks_node_groups_defaults"></a> [eks\_node\_groups\_defaults](#input\_eks\_node\_groups\_defaults) | Default configuration for all EKS node groups | <pre>object({<br/>    instance_types             = list(string)<br/>    desired_size               = number<br/>    min_size                   = number<br/>    max_size                   = number<br/>    disk_size                  = number<br/>    disk_type                  = string<br/>    disk_encrypted             = bool<br/>    enable_bootstrap_user_data = bool<br/>    metadata_options           = map(string)<br/>    force_update_version       = bool<br/>    update_config              = map(number)<br/>    tags                       = map(string)<br/>  })</pre> | <pre>{<br/>  "desired_size": 2,<br/>  "disk_encrypted": true,<br/>  "disk_size": 50,<br/>  "disk_type": "gp3",<br/>  "enable_bootstrap_user_data": false,<br/>  "force_update_version": false,<br/>  "instance_types": [<br/>    "t3.medium"<br/>  ],<br/>  "max_size": 5,<br/>  "metadata_options": {<br/>    "http_endpoint": "enabled",<br/>    "http_put_response_hop_limit": "1",<br/>    "http_tokens": "required",<br/>    "instance_metadata_tags": "disabled"<br/>  },<br/>  "min_size": 1,<br/>  "tags": {},<br/>  "update_config": {<br/>    "max_unavailable_percentage": 33<br/>  }<br/>}</pre> | no |
| <a name="input_eks_pod_identity_agent_version"></a> [eks\_pod\_identity\_agent\_version](#input\_eks\_pod\_identity\_agent\_version) | Version of Pod Identity Agent add-on (null = latest compatible version) | `string` | `null` | no |
| <a name="input_enabled_cluster_log_types"></a> [enabled\_cluster\_log\_types](#input\_enabled\_cluster\_log\_types) | List of control plane logging types to enable | `list(string)` | <pre>[<br/>  "api",<br/>  "audit",<br/>  "authenticator",<br/>  "controllerManager",<br/>  "scheduler"<br/>]</pre> | no |
| <a name="input_endpoint_private_access"></a> [endpoint\_private\_access](#input\_endpoint\_private\_access) | Enable private API server endpoint | `bool` | `true` | no |
| <a name="input_endpoint_public_access"></a> [endpoint\_public\_access](#input\_endpoint\_public\_access) | Enable public API server endpoint | `bool` | `true` | no |
| <a name="input_kube_proxy_version"></a> [kube\_proxy\_version](#input\_kube\_proxy\_version) | Version of kube-proxy add-on | `string` | `null` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | Kubernetes version for the EKS cluster | `string` | `"1.31"` | no |
| <a name="input_manage_aws_auth_configmap"></a> [manage\_aws\_auth\_configmap](#input\_manage\_aws\_auth\_configmap) | Whether to manage the aws-auth ConfigMap | `bool` | `true` | no |
| <a name="input_node_iam_role_arn"></a> [node\_iam\_role\_arn](#input\_node\_iam\_role\_arn) | IAM role ARN for EKS nodes (required if manage\_aws\_auth\_configmap is true) | `string` | `null` | no |
| <a name="input_node_security_group_id"></a> [node\_security\_group\_id](#input\_node\_security\_group\_id) | Security group ID for EKS nodes (optional - for cluster-to-node communication) | `string` | `null` | no |
| <a name="input_public_access_cidrs"></a> [public\_access\_cidrs](#input\_public\_access\_cidrs) | List of CIDR blocks that can access the public API endpoint | `list(string)` | <pre>[<br/>  "0.0.0.0/0"<br/>]</pre> | no |
| <a name="input_subnet_ids"></a> [subnet\_ids](#input\_subnet\_ids) | List of subnet IDs for the EKS cluster (should be private subnets) | `list(string)` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | Tags to apply to resources | `map(string)` | `{}` | no |
| <a name="input_vpc_cni_version"></a> [vpc\_cni\_version](#input\_vpc\_cni\_version) | Version of VPC CNI add-on | `string` | `null` | no |
| <a name="input_vpc_id"></a> [vpc\_id](#input\_vpc\_id) | VPC ID where the cluster will be created | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudwatch_log_group_arn"></a> [cloudwatch\_log\_group\_arn](#output\_cloudwatch\_log\_group\_arn) | ARN of the CloudWatch log group for EKS cluster logs |
| <a name="output_cloudwatch_log_group_name"></a> [cloudwatch\_log\_group\_name](#output\_cloudwatch\_log\_group\_name) | Name of the CloudWatch log group for EKS cluster logs |
| <a name="output_cluster_arn"></a> [cluster\_arn](#output\_cluster\_arn) | The Amazon Resource Name (ARN) of the cluster |
| <a name="output_cluster_certificate_authority_data"></a> [cluster\_certificate\_authority\_data](#output\_cluster\_certificate\_authority\_data) | Base64 encoded certificate data required to communicate with the cluster |
| <a name="output_cluster_endpoint"></a> [cluster\_endpoint](#output\_cluster\_endpoint) | Endpoint for EKS control plane |
| <a name="output_cluster_iam_role_arn"></a> [cluster\_iam\_role\_arn](#output\_cluster\_iam\_role\_arn) | IAM role ARN of the EKS cluster |
| <a name="output_cluster_iam_role_name"></a> [cluster\_iam\_role\_name](#output\_cluster\_iam\_role\_name) | IAM role name of the EKS cluster |
| <a name="output_cluster_id"></a> [cluster\_id](#output\_cluster\_id) | The name/id of the EKS cluster |
| <a name="output_cluster_oidc_issuer_url"></a> [cluster\_oidc\_issuer\_url](#output\_cluster\_oidc\_issuer\_url) | The URL on the EKS cluster OIDC Issuer |
| <a name="output_cluster_platform_version"></a> [cluster\_platform\_version](#output\_cluster\_platform\_version) | The platform version for the cluster |
| <a name="output_cluster_security_group_id"></a> [cluster\_security\_group\_id](#output\_cluster\_security\_group\_id) | Security group ID attached to the EKS cluster |
| <a name="output_cluster_version"></a> [cluster\_version](#output\_cluster\_version) | The Kubernetes server version for the cluster |
| <a name="output_coredns_addon_version"></a> [coredns\_addon\_version](#output\_coredns\_addon\_version) | Version of CoreDNS add-on |
| <a name="output_kube_proxy_addon_version"></a> [kube\_proxy\_addon\_version](#output\_kube\_proxy\_addon\_version) | Version of kube-proxy add-on |
| <a name="output_oidc_provider_arn"></a> [oidc\_provider\_arn](#output\_oidc\_provider\_arn) | ARN of the OIDC Provider for EKS |
| <a name="output_oidc_provider_url"></a> [oidc\_provider\_url](#output\_oidc\_provider\_url) | URL of the OIDC Provider for EKS |
| <a name="output_vpc_cni_addon_version"></a> [vpc\_cni\_addon\_version](#output\_vpc\_cni\_addon\_version) | Version of VPC CNI add-on |
<!-- END_TF_DOCS -->