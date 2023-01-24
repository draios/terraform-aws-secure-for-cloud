# Sysdig Secure for Cloud in AWS<br/>[ Example :: Single-Account ]

Deploy Sysdig Secure for Cloud in a single AWS account.<br/>
All the required resources and workloads will be run under the same account.


### Notice
* All Sysdig Secure for Cloud features **but [Image Scanning](https://docs.sysdig.com/en/docs/sysdig-secure/scanning/)** are enabled by default. You can enable it through `deploy_image_scanning_ecr` and `deploy_image_scanning_ecs` input variable parameters.<br/><br/>
* **Resource creation inventory** Find all the resources created by Sysdig examples in the resource-group `sysdig-secure-for-cloud` (AWS Resource Group & Tag Editor) <br/><br/>
* **Deployment cost** This example will create resources that cost money.<br/>Run `terraform destroy` when you don't need them anymore

![single-account diagram](https://raw.githubusercontent.com/sysdiglabs/terraform-aws-secure-for-cloud/master/examples/single-account-ecs/diagram-single.png)


## Prerequisites

Minimum requirements:

1. Configure [Terraform **AWS** Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
1. Secure requirements, as input variable value
    ```
    sysdig_secure_api_token=<SECURE_API_TOKEN>
    ```


## Usage

For quick testing, use this snippet on your terraform files

```terraform
terraform {
  required_providers {
    sysdig = {
      source = "sysdiglabs/sysdig"
    }
  }
}

provider "sysdig" {
  sysdig_secure_url       = "https://secure-staging.sysdig.com"
  sysdig_secure_api_token = "4fc06da6-6406-401c-bdd1-6d258573e681"
}

provider "aws" {
  region = "us-east-1"
}

module "secure-for-cloud_example_single-account" {
  source           = "../../terraform-aws-secure-for-cloud/examples/single-account-ecs"
  name             = "sameer-name"
  role_name        = "sameer-role2"
  trusted_identity = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id      = "b26e5d571ba8f8646e06ff8a8963a84b"
}

output "role_arn" {
  value       = module.secure-for-cloud_example_single-account.role_arn
  description = "ARN of cspm role"
}

output "cloudtrail_sns_topic_arn" {
  value       = module.secure-for-cloud_example_single-account.cloudtrail_sns_topic_arn
  description = "ARN of cloudtrail sns topic"
}

```

See [inputs summary](#inputs) or module module [`variables.tf`](https://github.com/sysdiglabs/terraform-aws-secure-for-cloud/blob/master/examples/single-account/variables.tf) file for more optional configuration.

To run this example you need have your [aws account profile configured in CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) and to execute:
```terraform
$ terraform init
$ terraform plan
$ terraform apply
```

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
| <a name="provider_sysdig"></a> [sysdig](#provider\_sysdig) | >= 0.5.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_connector"></a> [cloud\_connector](#module\_cloud\_connector) | ../../modules/services/cloud-connector-ecs | n/a |
| <a name="module_cloudtrail"></a> [cloudtrail](#module\_cloudtrail) | ../../modules/infrastructure/cloudtrail | n/a |
| <a name="module_cspm_single"></a> [cspm\_single](#module\_cspm\_single) | ../../modules/services/trust-relationship | n/a |
| <a name="module_ecs_vpc"></a> [ecs\_vpc](#module\_ecs\_vpc) | ../../modules/infrastructure/ecs-vpc | n/a |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | ../../modules/infrastructure/resource-group | n/a |
| <a name="module_ssm"></a> [ssm](#module\_ssm) | ../../modules/infrastructure/ssm | n/a |

## Resources

| Name | Type |
|------|------|
| [sysdig_secure_connection.current](https://registry.terraform.io/providers/sysdiglabs/sysdig/latest/docs/data-sources/secure_connection) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | The name of sysdig trusted identity | `string` | n/a | yes |
| <a name="input_cloudtrail_is_multi_region_trail"></a> [cloudtrail\_is\_multi\_region\_trail](#input\_cloudtrail\_is\_multi\_region\_trail) | true/false whether cloudtrail will ingest multiregional events | `bool` | `true` | no |
| <a name="input_cloudtrail_kms_enable"></a> [cloudtrail\_kms\_enable](#input\_cloudtrail\_kms\_enable) | true/false whether cloudtrail delivered events to S3 should persist encrypted | `bool` | `true` | no |
| <a name="input_cloudtrail_s3_bucket_expiration_days"></a> [cloudtrail\_s3\_bucket\_expiration\_days](#input\_cloudtrail\_s3\_bucket\_expiration\_days) | Number of days that the logs will persist in the bucket | `number` | `5` | no |
| <a name="input_cloudtrail_sns_arn"></a> [cloudtrail\_sns\_arn](#input\_cloudtrail\_sns\_arn) | ARN of a pre-existing cloudtrail\_sns. If defaulted, a new cloudtrail will be created. If specified, sysdig deployment account and region must match with the specified SNS | `string` | `"create"` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of a pre-existing ECS (elastic container service) cluster. If defaulted, a new ECS cluster/VPC/Security Group will be created. If specified all three parameters `ecs_cluster_name`, `ecs_vpc_id` and `ecs_vpc_subnets_private_ids` are required. | `string` | `"create"` | no |
| <a name="input_ecs_task_cpu"></a> [ecs\_task\_cpu](#input\_ecs\_task\_cpu) | Amount of CPU (in CPU units) to reserve for cloud-connector task | `string` | `"256"` | no |
| <a name="input_ecs_task_memory"></a> [ecs\_task\_memory](#input\_ecs\_task\_memory) | Amount of memory (in megabytes) to reserve for cloud-connector task | `string` | `"512"` | no |
| <a name="input_ecs_vpc_id"></a> [ecs\_vpc\_id](#input\_ecs\_vpc\_id) | ID of the VPC where the workload is to be deployed. If defaulted a new VPC will be created. If specified all three parameters `ecs_cluster_name`, `ecs_vpc_id` and `ecs_vpc_subnets_private_ids` are required | `string` | `"create"` | no |
| <a name="input_ecs_vpc_region_azs"></a> [ecs\_vpc\_region\_azs](#input\_ecs\_vpc\_region\_azs) | List of Availability Zones for ECS VPC creation. e.g.: ["apne1-az1", "apne1-az2"]. If defaulted, two of the default 'aws\_availability\_zones' datasource will be taken | `list(string)` | `[]` | no |
| <a name="input_ecs_vpc_subnets_private_ids"></a> [ecs\_vpc\_subnets\_private\_ids](#input\_ecs\_vpc\_subnets\_private\_ids) | List of VPC subnets where workload is to be deployed. If defaulted new subnets will be created within the VPC. A minimum of two subnets is suggested. If specified all three parameters `ecs_cluster_name`, `ecs_vpc_id` and `ecs_vpc_subnets_private_ids` are required. | `list(string)` | `[]` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances | `string` | `"sfc"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS region where resources are deployed | `string` | `""` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Role name for cspm | `string` | `"sfc-cspm-role"` | no |
| <a name="input_sysdig_secure_api_token"></a> [sysdig\_secure\_api\_token](#input\_sysdig\_secure\_api\_token) | Api token for deployment | `string` | `""` | no |
| <a name="input_sysdig_secure_endpoint"></a> [sysdig\_secure\_endpoint](#input\_sysdig\_secure\_endpoint) | Backend url where results are sent | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning | `map(string)` | <pre>{<br>  "product": "sysdig-secure-for-cloud"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudtrail_sns_topic_arn"></a> [cloudtrail\_sns\_topic\_arn](#output\_cloudtrail\_sns\_topic\_arn) | ARN of cloudtrail\_sns topic |
| <a name="output_role_arn"></a> [role\_arn](#output\_role\_arn) | ARN of cspm role |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Authors

Module is maintained and supported by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
