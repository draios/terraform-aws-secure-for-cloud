# AWS EKS Module

This module will onboard AWS EKS clusters into Agentless scanning.

The following resource will be created in each EKS cluster:
- EKS access entry that assigns `AmazonEKSViewPolicy` to Sysdig's IAM principal
- IAM role that grants Sysdig permissions to pull ECR images

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.7 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_awscc"></a> [aws](#provider\_awscc) | >= 0.69 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [awscc_eks_access_entry](https://registry.terraform.io/providers/hashicorp/awscc/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_clusters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_clusters) | data source |
| [aws_eks_cluster](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/eks_cluster) | data source |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="role_name"></a> [role_name](#role\_name) | (Required) IAM role that Sysdig will assume to access the EKS clusters | `string` | N/A | Yes |
| <a name="var_clusters"></a> [clusters](#var\_clusters) | (Optional) To only scan some public clusters, enter their names here. Please note that only clusters with authentication mode set to API or API_AND_CONFIG_MAP will be onboarded. | `set(string)` | Empty list | No |
| <a name="var_onboard_all_clusters"></a> [onboard_all_clusters](#var\_onboard\_all\_clusters) | (Optional) Set the value to true to ensure Sysdig scans all public clusters. Please note that only clusters with authentication mode set to API or API_AND_CONFIG_MAP will be onboarded. | `bool` | `false` | No |
| <a name="var_deploy_global_resources"></a> [deploy\_global\_resources](#var\_deploy\_global\_resources) | (Optional) Setting this field to 'true' creates an IAM role that allows Sysdig to pull ECR images in order to scan them. | `bool` | `false` | No |
| <a name="var_external_id"></a> [external\_id](#var\_external\_id) | (Optional) This value should be provided by Sysdig. External ID is optional information that you can use in an IAM role trust policy to designate who in Sysdig can assume the role | `string` | | No |
| <a name="var_name"></a> [name](#var\_name) | (Optional) This value should be provided by Sysdig. The field refers to an installation name, which will also be used to name the IAM role that grants access to pull ECR images | `string` | | No |
| <a name="var_tags"></a> [tags](#var\_tags) | (Optional) This value should be provided by Sysdig. Tags that will be associated with the IAM role. | `map(string)` | <pre>{ "product": "sysdig-secure-for-cloud" }</pre> | No |
| <a name="var_trusted_identity"></a> [trusted\_identity](#var\_trusted\_identity) | (Optional) This value should be provided by Sysdig. The field refers to Sysdig's IAM role that will be authorized to pull ECR images | `string` | | No |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.

