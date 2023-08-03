# AWS Cloud Logs Module

This Module creates the resources required to send CloudTrail logs to Sysdig by enabling access to the CloudTrail associated s3 bucket through a dedicated IAM role.


The following resources will be created in each instrumented account:
- An IAM Role and associated policies that gives the ingestion component in Sysdig's account permission to list and retrieve items from it. 

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.39.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 5.9.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.cloudlogs_s3_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy_document.assume_cloudlogs_s3_access_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.cloudlogs_s3_access_policy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | (Required) The name of your s3 bucket associated with your Clloudtrail trail | `string` | n/a | yes |
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | (Required) Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_region"></a> [region](#input\_region) | (Optional) Default region for resource creation | `string` | `"eu-central-1"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | (Required) The name of the IAM Role that will enable access to the Cloudtrail logs | `string` | `"cloudtrail-s3-bucket-read-access"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning | `map(string)` | <pre>{<br>  "product": "sysdig-secure-for-cloud"<br>}</pre> | no |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | (Required) The name of Sysdig trusted identity | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of CloudLogs role |

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
