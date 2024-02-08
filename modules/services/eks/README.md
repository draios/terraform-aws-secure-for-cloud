# AWS Trust Relationship Module

This module will onboard AWS EKS clusters into Agentless scanning.

The following resource will be created in each EKS cluster:
- EKS access entry that assigns `AmazonEKSViewPolicy` to Sysdig's IAM principal. 

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

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="var_principal_arn"></a> [principal_arn](#var\_principal\_arn) | Sysdig's IAM Principal ARN which will access the EKS clusters | `string` | N/A | Yes |
| <a name="var_clusters"></a> [clusters](#var\_clusters) | The list of clusters to be scanned by Sysdig (when 'onboard_all_clusters' is set to false, only the clusters specified in this list will be scanned) | `set(string)` | Empty list | No |
| <a name="var_onboard_all_clusters"></a> [onboard_all_clusters](#var\_onboard\_all\_clusters) | If set to `true`, all public clusters will be onboarded | `bool` | `false` | No |


## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.

