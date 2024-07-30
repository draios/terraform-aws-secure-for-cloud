# AWS Event Bridge Module

This Module creates the resources required to send CloudTrail logs to Sysdig via AWS EventBridge.

The following resources will be created in each instrumented account:
- An EventBridge Rule that captures all CloudTrail events from the defaul EventBridge Bus
- An EventBridge Target that sends these events to an EventBridge Bus is Sysdig's AWS Account
- An IAM Role and associated policies that gives the EventBridge Bus in the source account permission to call PutEvent on the EventBridge Bus in Sysdig's Account.

When run in Organizational mode, this module will be deployed as a CloudFormation StackSet that should be applied to the management account. This will create the above resources in each account in the organization, and automatically in any member accounts that are later added to the organization.


<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.60.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.60.0 |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_cloudformation_stack_set.eb-role-stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set.eb-rule-stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set.mgmt-stackset](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set) | resource |
| [aws_cloudformation_stack_set_instance.eb_role_stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudformation_stack_set_instance.mgmt_acc_stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudformation_stack_set_instance.stackset_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudformation_stack_set_instance) | resource |
| [aws_cloudwatch_event_rule.sysdig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_rule) | resource |
| [aws_cloudwatch_event_target.sysdig](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_event_target) | resource |
| [aws_iam_role.event_bus_invoke_remote_event_bus](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_policy_document.cloud_trail_events](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_organizations_organization.org](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/organizations_organization) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_target_event_bus_arn"></a> [target\_event\_bus\_arn](#input\_target\_event\_bus\_arn) | (Required) The ARN of Sysdig's event bus that will receive events from your account | `string` | n/a | yes |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | The name of sysdig trusted identity | `string` | n/a | yes |
| <a name="input_deploy_global_resources"></a> [deploy\_global\_resources](#input\_deploy\_global\_resources) | (Optional) Set this field to 'true' to deploy EventBridge to an AWS Organization (Or specific OUs) | `bool` | `false` | no |
| <a name="input_event_pattern"></a> [event\_pattern](#input\_event\_pattern) | Event pattern for CloudWatch Event Rule | `string` | `"{\n  \"detail-type\": [\n    \"AWS API Call via CloudTrail\",\n    \"AWS Console Sign In via CloudTrail\",\n    \"AWS Service Event via CloudTrail\",\n    \"Object Access Tier Changed\",\n    \"Object ACL Updated\",\n    \"Object Created\",\n    \"Object Deleted\",\n    \"Object Restore Completed\",\n    \"Object Restore Expired\",\n    \"Object Restore Initiated\",\n    \"Object Storage Class Changed\",\n    \"Object Tags Added\",\n    \"Object Tags Deleted\",\n    \"GuardDuty Finding\"\n  ]\n}\n"` | no |
| <a name="input_failure_tolerance_percentage"></a> [failure\_tolerance\_percentage](#input\_failure\_tolerance\_percentage) | The percentage of accounts, per Region, for which stack operations can fail before AWS CloudFormation stops the operation in that Region | `number` | `90` | no |
| <a name="input_is_organizational"></a> [is\_organizational](#input\_is\_organizational) | (Optional) Set this field to 'true' to deploy EventBridge to an AWS Organization (Or specific OUs) | `bool` | `false` | no |
| <a name="input_mgt_stackset"></a> [mgt\_stackset](#input\_mgt\_stackset) | (Optional) Indicates if the management stackset should be deployed | `bool` | `true` | no |
| <a name="input_name"></a> [name](#input\_name) | (Optional) Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances | `string` | `"sysdig"` | no |
| <a name="input_org_units"></a> [org\_units](#input\_org\_units) | (Optional) List of Organization Unit IDs in which to setup EventBridge. By default, EventBridge will be setup in all accounts within the Organization. This field is ignored if `is_organizational = false` | `set(string)` | `[]` | no |
| <a name="input_regions"></a> [regions](#input\_regions) | (Optional) List of regions in which to setup EventBridge. By default, current region is selected | `set(string)` | `[]` | no |
| <a name="input_role_arn"></a> [role\_arn](#input\_role\_arn) | (Optional) IAM role created for event-bridge. If already created value is needed to be passed | `string` | `""` | no |
| <a name="input_rule_state"></a> [rule\_state](#input\_rule\_state) | State of the rule. When state is ENABLED, the rule is enabled for all events except those delivered by CloudTrail. To also enable the rule for events delivered by CloudTrail, set state to ENABLED\_WITH\_ALL\_CLOUDTRAIL\_MANAGEMENT\_EVENTS. | `string` | `"ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"` | no |
| <a name="input_stackset_admin_role_arn"></a> [stackset\_admin\_role\_arn](#input\_stackset\_admin\_role\_arn) | (Optional) stackset admin role to run SELF\_MANAGED stackset | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | (Optional) Tags to be attached to all Sysdig resources. | `map(string)` | <pre>{<br>  "product": "sysdig"<br>}</pre> | no |
| <a name="input_timeout"></a> [timeout](#input\_timeout) | Default timeout values for create, update, and delete operations | `string` | `"30m"` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of cspm role |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
