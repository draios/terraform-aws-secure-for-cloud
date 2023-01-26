# Cloud Connector

A task deployed on an **ECS deployment** will detect events in your infrastructure.

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.3.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_sysdig"></a> [sysdig](#requirement\_sysdig) | >= 0.5.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_sysdig"></a> [sysdig](#provider\_sysdig) | >= 0.5.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_connector_sqs"></a> [cloud\_connector\_sqs](#module\_cloud\_connector\_sqs) | ../../infrastructure/sqs-sns-subscription | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_cloudwatch_log_group.log](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_group) | resource |
| [aws_cloudwatch_log_stream.stream](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/cloudwatch_log_stream) | resource |
| [aws_ecs_service.service](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_service) | resource |
| [aws_ecs_task_definition.task_definition](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/ecs_task_definition) | resource |
| [aws_iam_role.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role.task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_policy_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_policy_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_policy_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_iam_role_policy.task_read_parameters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy) | resource |
| [aws_security_group.sg](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/security_group) | resource |
| [aws_ecs_cluster.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ecs_cluster) | data source |
| [aws_iam_policy_document.execution](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.execution_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam_role_task_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam_role_task_policy_s3](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.iam_role_task_policy_sqs](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_policy_document.task_read_parameters](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_iam_role.task_inherited](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_role) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [aws_ssm_parameter.sysdig_secure_api_token](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ssm_parameter) | data source |
| [sysdig_secure_connection.current](https://registry.terraform.io/providers/sysdiglabs/sysdig/latest/docs/data-sources/secure_connection) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of a pre-existing ECS (elastic container service) cluster | `string` | n/a | yes |
| <a name="input_ecs_vpc_id"></a> [ecs\_vpc\_id](#input\_ecs\_vpc\_id) | ID of the VPC where the workload is to be deployed. | `string` | n/a | yes |
| <a name="input_ecs_vpc_subnets_private_ids"></a> [ecs\_vpc\_subnets\_private\_ids](#input\_ecs\_vpc\_subnets\_private\_ids) | List of VPC subnets where workload is to be deployed. | `list(string)` | n/a | yes |
| <a name="input_secure_api_token_secret_name"></a> [secure\_api\_token\_secret\_name](#input\_secure\_api\_token\_secret\_name) | Sysdig Secure API token SSM parameter name | `string` | n/a | yes |
| <a name="input_cloudwatch_log_retention"></a> [cloudwatch\_log\_retention](#input\_cloudwatch\_log\_retention) | Days to keep logs for CloudConnector | `number` | `5` | no |
| <a name="input_connector_ecs_task_role_name"></a> [connector\_ecs\_task\_role\_name](#input\_connector\_ecs\_task\_role\_name) | Default ecs cloudconnector task role name | `string` | `"ECSTaskRole"` | no |
| <a name="input_ecs_task_cpu"></a> [ecs\_task\_cpu](#input\_ecs\_task\_cpu) | Amount of CPU (in CPU units) to reserve for cloud-connector task | `string` | `"256"` | no |
| <a name="input_ecs_task_memory"></a> [ecs\_task\_memory](#input\_ecs\_task\_memory) | Amount of memory (in megabytes) to reserve for cloud-connector task | `string` | `"512"` | no |
| <a name="input_existing_cloudtrail_config"></a> [existing\_cloudtrail\_config](#input\_existing\_cloudtrail\_config) | Optional block. If not set, a new cloudtrail, sns and sqs resources will be created<br/><br>If there's an existing cloudtrail, input mandatory attributes, and one of the 1 or 2 labeled optionals.<br><ul><br>  <li>cloudtrail\_sns\_arn: Optional 1. ARN of a cloudtrail-sns topic. If specified, deployment region must match Cloudtrail S3 bucket region</li><br>  <li>cloudtrail\_s3\_sns\_sqs\_arn: Optional 2. ARN of the queue that will ingest events forwarded from an existing cloudtrail\_s3\_sns</li><br>  <li>cloudtrail\_s3\_sns\_sqs\_url: Optional 2. URL of the queue that will ingest events forwarded from an existing cloudtrail\_s3\_sns<br/>sqs:ReceiveMessage and sqs:DeleteMessage permissions have to be provided to the compute role</li><br></ul> | <pre>object({<br>    cloudtrail_sns_arn        = optional(string)<br>    cloudtrail_s3_sns_sqs_arn = optional(string)<br>    cloudtrail_s3_sns_sqs_url = optional(string)<br>  })</pre> | <pre>{<br>  "cloudtrail_s3_sns_sqs_arn": null,<br>  "cloudtrail_s3_sns_sqs_url": null,<br>  "cloudtrail_sns_arn": "create"<br>}</pre> | no |
| <a name="input_extra_env_vars"></a> [extra\_env\_vars](#input\_extra\_env\_vars) | Extra environment variables for the Cloud Connector deployment | `map(string)` | `{}` | no |
| <a name="input_image"></a> [image](#input\_image) | Image of the cloud connector to deploy | `string` | `"quay.io/sysdig/cloud-connector:latest"` | no |
| <a name="input_is_organizational"></a> [is\_organizational](#input\_is\_organizational) | true/false whether `organizational_config` should be used to handle organizational setup | `bool` | `false` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances | `string` | `"sfc-cloudconnector"` | no |
| <a name="input_organizational_config"></a> [organizational\_config](#input\_organizational\_config) | organizational\_config. following attributes must be given<br><ul><br>  <li>`sysdig_secure_for_cloud_role_arn` for cloud-connector assumeRole in order to read cloudtrail s3 events</li><br>  <li>`connector_ecs_task_role_name` which has been granted trusted-relationship over the secure\_for\_cloud\_role</li><br>  <li>`organizational_role_per_account` is the name of the organizational role deployed by AWS in each account of the organization. used for image-scanning only</li><br></ul> | <pre>object({<br>    sysdig_secure_for_cloud_role_arn = string<br>    organizational_role_per_account  = string<br>    connector_ecs_task_role_name     = string<br>  })</pre> | <pre>{<br>  "connector_ecs_task_role_name": null,<br>  "organizational_role_per_account": null,<br>  "sysdig_secure_for_cloud_role_arn": null<br>}</pre> | no |
| <a name="input_tags"></a> [tags](#input\_tags) | sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning | `map(string)` | <pre>{<br>  "product": "sysdig-secure-for-cloud"<br>}</pre> | no |
| <a name="input_verify_ssl"></a> [verify\_ssl](#input\_verify\_ssl) | true/false to determine ssl verification for sysdig\_secure\_url | `bool` | `true` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

## Authors

Module is maintained and supported by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
