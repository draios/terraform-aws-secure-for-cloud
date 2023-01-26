# Cloud Bench deploy in AWS Module


Deployed on the **target AWS account(s)**:

- The required IAM Role and IAM Policies (`arn:aws:iam::aws:policy/SecurityAudit`)  to allow Sysdig to run AWS Benchmarks on your behalf.
    - A Sysdig provided `ExternalId` will be used.
    - This is done using `aws_cloudformation_stack_set`.

Deployed on **Sysdig Backend**
- The required provisioning on Sysdig Backend to use the `ExternalId`-basedIAM Role with an AssumeRole.
- An `aws_foundations_bench-1.3.0` benchmak task schedule on a random hour of the day `rand rand * * *`

This module will be deployed as a StackSet and it will take into account newly member accounts added to the Organization.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 3.62.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 3.62.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack_set.stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_iam_role.cspm_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.cspm_security_audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_caller_identity.me](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy.security_audit](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy) | data source |
| [aws_iam_policy_document.trust_relationship](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | The name of the IAM Role that will be created. | `string` | n/a | yes |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | The name of sysdig trusted identity | `string` | n/a | yes |
| <a name="input_is_organizational"></a> [is\_organizational](#input\_is\_organizational) | true/false whether secure-for-cloud should be deployed in an organizational setup (all accounts of org) or not (only on default aws provider account) | `bool` | `false` | no |
| <a name="input_org_units"></a> [org\_units](#input\_org\_units) | Org unit id to install cspm | `set(string)` | `[]` | no |
| <a name="input_provision_caller_account"></a> [provision\_caller\_account](#input\_provision\_caller\_account) | true/false whether to provision the aws provider account (if is\_organizational=true management account, if is\_organizational=false it will depend on the provider setup on the caller module | `bool` | `true` | no |
| <a name="input_region"></a> [region](#input\_region) | Default region for resource creation in organization mode | `string` | `"eu-central-1"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning | `map(string)` | <pre>{<br>  "product": "sysdig-secure-for-cloud"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cspm_role_arn"></a> [cspm\_role\_arn](#output\_cspm\_role\_arn) | ARN of cspm role |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
