# AWS EKS Module

This module will grant Sysdig view-only access to the AWS EKS clusters specified in the `clusters` variable.

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

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_eks_access_entry](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_entry) | resource |
| [aws_eks_access_policy_association](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/eks_access_policy_association) | resource |
| [aws_iam_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_policy_document](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="var_eks_role_name"></a> [eks_role_name](#var\_eks\_role\_name) | (Required) IAM role that Sysdig will assume to access the EKS clusters. Prerequisite: Before this module can be invoked, Sysdig's CSPM Terraform module needs to create this role. | `string` | | Yes |
| <a name="var_clusters"></a> [clusters](#var\_clusters) | (Required) List the clusters that Sysdig will scan. Please note that only clusters with authentication mode set to API or API_AND_CONFIG_MAP will be onboarded. | `set(string)` | | Yes |
| <a name="var_deploy_global_resources"></a> [deploy\_global\_resources](#var\_deploy\_global\_resources) | (Optional) Setting this field to 'true' creates an IAM role that allows Sysdig to pull ECR images in order to scan them. | `bool` | `false` | No |
| <a name="var_trusted_identity"></a> [trusted\_identity](#var\_trusted\_identity) | (Optional) This value should be provided by Sysdig. The field refers to Sysdig's IAM role that will be authorized to pull ECR images | `string` | | No |
| <a name="var_ecr_role_name"></a> [ecr_role_name](#var\_ecr\_role\_name) | (Optional) This value should be provided by Sysdig. The field refers to an installation name, which will also be used to name the IAM role that grants access to pull ECR images | `string` | | No |
| <a name="var_external_id"></a> [external\_id](#var\_external\_id) | (Optional) This value should be provided by Sysdig. External ID is optional information that you can use in an IAM role trust policy to designate who in Sysdig can assume the role | `string` | | No |
| <a name="var_tags"></a> [tags](#var\_tags) | (Optional) This value should be provided by Sysdig. Tags that will be associated with the IAM role. | `map(string)` | <pre>{ "product": "sysdig-secure-for-cloud" }</pre> | No |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.

