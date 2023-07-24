# AWS Agentless Scanning Module

This Module creates the resources required to perform agentless EC2 host scanning.

The following resources will be created in each instrumented account:
- An IAM Role and associated policies that allows Sysdig to perform tasks necessary for agentless scanning.
- A KMS key used to transcript volume snapshots in the each region. Alias for this key in each region.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.39.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.39.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack_set.mgmt_acc_resources_stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set.ou_resources_stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set.scanning_role_stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.mgmt_acc_stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudformation_stack_set_instance.ou_stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudformation_stack_set_instance.scanning_role_stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_iam_policy.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_alias.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.agentless_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_agentless_account_id"></a> [agentless\_account\_id](#input\_agentless\_account\_id) | The identifier of the account that will receive volume snapshots | `string` | `"878070807337"` | no |
| <a name="input_deploy_global_resources"></a> [deploy\_global\_resources](#input\_deploy\_global\_resources) | (Optional) Set this field to 'true' to deploy Agentless Scanning to an AWS Organization (Or specific OUs) | `bool` | `false` | no |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_instrumented_regions"></a> [instrumented\_regions](#input\_instrumented\_regions) | (Optional) List of additional instrumented regions in which to setup Agentless Scanning. | `set(string)` | `[]` | no |
| <a name="input_is_organizational"></a> [is\_organizational](#input\_is\_organizational) | (Optional) Set this field to 'true' to deploy Agentless Scanning to an AWS Organization (Or specific OUs) | `bool` | `false` | no |
| <a name="input_kms_key_alias"></a> [kms\_key\_alias](#input\_kms\_key\_alias) | The alias of the KMS key used to encrypt the data plane secrets | `string` | `"sysdig-secure-scanning"` | no |
| <a name="input_kms_key_deletion_window"></a> [kms\_key\_deletion\_window](#input\_kms\_key\_deletion\_window) | Deletion window for shared KMS key | `number` | `7` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the installation. Assigned to most child resource(s) | `string` | `"sysdig-secure-scanning"` | no |
| <a name="input_org_units"></a> [org\_units](#input\_org\_units) | (Optional) List of Organization Unit IDs in which to setup Agentless Scanning. By default, Agentless Scanning will be setup in all accounts within the Organization. This field is ignored if `is_organizational = false` | `set(string)` | `[]` | no |
| <a name="input_stackset_admin_role_arn"></a> [stackset\_admin\_role\_arn](#input\_stackset\_admin\_role\_arn) | (Optional) stackset admin role to run SELF\_MANAGED stackset | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning | `map(string)` | <pre>{<br>  "product": "sysdig-secure-for-cloud"<br>}</pre> | no |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | The name of sysdig trusted identity | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agentless_role_arn"></a> [agentless\_role\_arn](#output\_agentless\_role\_arn) | Role used by Sysdig BE for Secure Agentless |
| <a name="output_kms_key"></a> [kms\_key](#output\_kms\_key) | KMS key ID and ARN |
| <a name="output_kms_key_alias"></a> [kms\_key\_alias](#output\_kms\_key\_alias) | KMS key alias |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
