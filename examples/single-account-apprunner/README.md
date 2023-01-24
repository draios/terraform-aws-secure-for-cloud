# Sysdig Secure for Cloud in AWS<br/>[ Example :: App Runner ]

Deploy Sysdig Secure for Cloud in a single AWS account using App Runner.<br/>
All the required resources and workloads will be run under the same account.

![single-account diagram on apprunner](https://raw.githubusercontent.com/sysdiglabs/terraform-aws-secure-for-cloud/master/examples/single-account-apprunner/diagram-single.png)

## Prerequisites

Minimum requirements:

1. Configure [Terraform **AWS** Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs)
1. Secure requirements, as input variable value
    ```
    sysdig_secure_api_token=<SECURE_API_TOKEN>
    ```

## Notice

* **Resource creation inventory** Find all the resources created by Sysdig examples in the resource-group `sysdig-secure-for-cloud` (AWS Resource Group & Tag Editor) <br/><br/>
* **Deployment cost** This example will create resources that cost money.<br/>Run `terraform destroy` when you don't need them anymore <br/><br/>
* **AppRunner enabled zones** AppRunner isn't available in all AWS zones, check [AppRunner Service endpoints](https://docs.aws.amazon.com/general/latest/gr/apprunner.html) for enabled zones.


## Usage

For quick testing, use this snippet on your terraform files

```terraform
terraform {
   required_providers {
      sysdig = {
         source  = "sysdiglabs/sysdig"
         version = ">=0.5.33"
      }
   }
}

provider "sysdig" {
   sysdig_secure_api_token = "<SYSDIG_SECURE_URL>"
   sysdig_secure_url       = "<SYSDIG_SECURE_API_TOKEN"
}

provider "aws" {
   region = "<AWS_REGION> Take care of AppRunner available zones: https://docs.aws.amazon.com/general/latest/gr/apprunner.html"
}

module "cloudvision_aws_apprunner_single_account" {
   source = "sysdiglabs/secure-for-cloud/aws//examples/single-account-apprunner"
}
```

to test it locally

```terraform
terraform {
  required_providers {
    sysdig = {
      source  = "sysdiglabs/sysdig"
      version = ">=0.5.33"
    }
  }
}

provider "sysdig" {
  sysdig_secure_api_token = "https://secure-staging.sysdig.com"
  sysdig_secure_url       = "4fc06da6-6406-401c-bdd1-6d258573e681"
}

provider "aws" {
  region = "us-east-1"
}

module "cloudvision_aws_apprunner_single_account" {
  source           = "../../terraform-aws-secure-for-cloud/examples/single-account-apprunner"
  role_name        = "sameer"
  name             = "sameer-test"
  trusted_identity = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id      = "b26e5d571ba8f8646e06ff8a8963a84b"
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
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.0.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.0.0 |
| <a name="requirement_sysdig"></a> [sysdig](#requirement\_sysdig) | >= 0.5.33 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_sysdig"></a> [sysdig](#provider\_sysdig) | >= 0.5.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_connector"></a> [cloud\_connector](#module\_cloud\_connector) | ../../modules/services/cloud-connector-apprunner | n/a |
| <a name="module_cloudtrail"></a> [cloudtrail](#module\_cloudtrail) | ../../modules/infrastructure/cloudtrail | n/a |
| <a name="module_cspm_single"></a> [cspm\_single](#module\_cspm\_single) | ../../modules/services/trust-relationship | n/a |
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
| <a name="input_cloudconnector_ecr_image_uri"></a> [cloudconnector\_ecr\_image\_uri](#input\_cloudconnector\_ecr\_image\_uri) | URI to cloudconnectors image on ECR | `string` | `"public.ecr.aws/o5x4u2t4/cloud-connector:latest"` | no |
| <a name="input_cloudtrail_is_multi_region_trail"></a> [cloudtrail\_is\_multi\_region\_trail](#input\_cloudtrail\_is\_multi\_region\_trail) | true/false whether cloudtrail will ingest multiregional events | `bool` | `true` | no |
| <a name="input_cloudtrail_kms_enable"></a> [cloudtrail\_kms\_enable](#input\_cloudtrail\_kms\_enable) | true/false whether cloudtrail delivered events to S3 should persist encrypted | `bool` | `true` | no |
| <a name="input_cloudtrail_sns_arn"></a> [cloudtrail\_sns\_arn](#input\_cloudtrail\_sns\_arn) | ARN of a pre-existing cloudtrail\_sns. If defaulted, a new cloudtrail will be created. ARN of a pre-existing cloudtrail\_sns. If defaulted, a new cloudtrail will be created. If specified, sysdig deployment account and region must match with the specified SNS | `string` | `"create"` | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances | `string` | `"sfc"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Role name for cspm | `string` | `"sfc-cspm-role"` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning | `map(string)` | <pre>{<br>  "product": "sysdig-secure-for-cloud"<br>}</pre> | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudtrail_sns_topic_arn"></a> [cloudtrail\_sns\_topic\_arn](#output\_cloudtrail\_sns\_topic\_arn) | ARN of cloudtrail\_sns topic |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->


## Authors

Module is maintained and supported by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
