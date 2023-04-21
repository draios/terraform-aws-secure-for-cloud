# Sysdig Event Bridge AWS Module

This Module creates the resources required to send CloudTrail logs to Sysdig via AWS EventBridge.

This module will provision the following resources in the source AWS account:

- An EventBridge Rule that captures all CloudTrail events from the defaul EventBridge Bus
- An EventBridge Target that sends these events to an EventBridge Bus is Sysdig's AWS Account
- An IAM Role and associated policies that gives the EventBridge Bus in the source account permission to call PutEvent on the EventBridge Bus in Sysdig's Account.

When run in Organizational mode, this module will be deployed as a CloudFormation StackSet that should be applied to the management account. This will create the above resources in each account in the organization, and automatically in any member accounts that are later added to the organization.


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
| [aws_cloudformation_stack_set.stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudwatch_event_rule.sysdig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.sysdig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.event_bus_invoke_remote_event_bus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_target_event_bus_arn"></a> [target\_event\_bus\_arn](#input\_target\_event\_bus\_arn) | (Required) The ARN of Sysdig's event bus that will receive events from your account | `string` | n/a | yes |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | The name of sysdig trusted identity | `string` | n/a | yes |
| <a name="input_deploy_global_resources"></a> [deploy\_global\_resources](#input\_deploy\_global\_resources) | (Optional) Set this field to 'true' to deploy EventBridge to an AWS Organization (Or specific OUs) | `bool` | `false` | no |
| <a name="input_is_organizational"></a> [is\_organizational](#input\_is\_organizational) | (Optional) Set this field to 'true' to deploy EventBridge to an AWS Organization (Or specific OUs) | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances | `string` | `"sysdig"` | no |
| <a name="input_organization_units"></a> [organization\_units](#input\_organization\_units) | (Optional) List of Organization Unit IDs in which to setup EventBridge. By default, EventBridge will be setup in all accounts within the Organization. This field is ignored if `is_organizational = false` | `set(string)` | `[]` | no |
| <a name="input_provision_management_account"></a> [provision\_management\_account](#input\_provision\_management\_account) | (Optional) Set this field to `true` to deploy EventBridge to the management account. By default, the management account will be instrumented. This field is ignored if `is_organizational = false` | `bool` | `true` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | (Optional) IAM role created for event-bridge. If already created value is needed to be passed | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Tags to be attached to all Sysdig resources. | `map(string)` | <pre>{<br>  "product": "sysdig"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of cspm role |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
