# Sysdig Secure Agentless Scanning AWS Module

This Module creates the resources required to perform agentless scanning.

This module will provision the following resources in the source AWS account:

- A KMS key use to transcript volume snapshots
- An IAM Role and associated policies that allows Sysdig to perform tasks necessary for agentless scaninng.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_policy.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy) | resource |
| [aws_iam_policy_attachment.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_policy_attachment) | resource |
| [aws_iam_role.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_kms_alias.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.agentless](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.agentless_assume_role_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.key_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_kms_key_deletion_window"></a> [kms\_key\_deletion\_window](#input\_kms\_key\_deletion\_window) | Deletion window for shared KMS key | `number` | `7` | no |
| <a name="input_name"></a> [name](#input\_name) | The name of the installation. Assigned to most child resource(s) | `string` | n/a | yes |
| <a name="input_tags"></a> [tags](#input\_tags) | sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning | `map(string)` | <pre>{<br>  "product": "sysdig-secure-for-cloud"<br>}</pre> | no |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | The name of sysdig trusted identity | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_agentless_role_arn"></a> [agentless\_role\_arn](#output\_agentless\_role\_arn) | Role used by Sysdig BE for Secure Agentless |
| <a name="output_kms_key"></a> [kms\_key](#output\_kms\_key) | Multi-region KMS key ID and ARN |
| <a name="output_kms_key_alias"></a> [kms\_key\_alias](#output\_kms\_key\_alias) | Multi-region KMS key alias |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
