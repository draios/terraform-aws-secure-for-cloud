# Sysdig Secure for Cloud in AWS<br/>[ Example :: Shared Organizational Trail ]

Assess the security of your organization.

Deploy Sysdig Secure for Cloud using an [AWS Organizational Cloudtrail](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/creating-trail-organization.html) that will fetch events from all organization member accounts (and the managed one too).

* In the **management account**
    * An Organizational Cloutrail will be deployed  (with required S3,SNS)
    * An additional role `SysdigSecureForCloudRole` will be created
        * to be able to read cloudtrail-s3 bucket events (and query cloudtrail-sqs) from sysdig workload member account.
        * scanning-only, to assumeRole over member-account role
          * to scan images pushed to ECR's that may be present in other member accounts.
          * to describe ECS task definitions and get images to be scanned, on clusters in other member accounts
* In the **user-provided member account**
    * All the Sysdig Secure for Cloud service-related resources/workload will be created

### Notice

* All Sysdig Secure for Cloud features **but [Image Scanning](https://docs.sysdig.com/en/docs/sysdig-secure/scanning/)** are enabled by default. You can enable it through `deploy_image_scanning_ecr` and `deploy_image_scanning_ecs` input variable parameters.<br/><br/>
* **Resource creation inventory** Find all the resources created by Sysdig examples in the resource-group `sysdig-secure-for-cloud` (AWS Resource Group & Tag Editor) <br/><br/>
* **Deployment cost** This example will create resources that cost money.<br/>Run `terraform destroy` when you don't need them anymore<br/><br/>
* For **free subscription** users, beware that this example may not deploy properly due to the [1 cloud-account limitation](https://docs.sysdig.com/en/docs/administration/administration-settings/subscription/#cloud-billing-free-tier). Open an Issue so we can help you here!

![organizational diagram](https://raw.githubusercontent.com/sysdiglabs/terraform-aws-secure-for-cloud/master/examples/organizational/diagram-org.png)

## Prerequisites

Minimum requirements:

1. Have an existing AWS account as the organization management account
    *  Within the Organization, following services must be enabled (Organization > Services)
        * Organizational CloudTrail
        * [Organizational CloudFormation StackSets](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/stacksets-orgs-enable-trusted-access.html)
2. Configure [Terraform **AWS** Provider](https://registry.terraform.io/providers/hashicorp/aws/latest/docs) for the `management` account of the organization
    * This provider credentials must be [able to manage cloudtrail creation](https://docs.aws.amazon.com/awscloudtrail/latest/userguide/creating-trail-organization.html)
      > You must be logged in with the management account for the organization to create an organization trail. You must also have sufficient permissions for the IAM user or role in the management account to successfully create an organization trail.

3. Organizational Multi-Account Setup, ONLY IF SCANNING feature is activated, a specific role is required, to enable Sysdig to impersonate on organization member-accounts and provide

   * The ability to pull ECR hosted images when they're allocated in a different account
   * The ability to query the ECS tasks that are allocated in different account, in order to fetch the image to be scanned
   <!-- * A solution to resolve current limitation when accessing an S3 bucket in a different region than where it's being called from-->
   * By default, it uses [AWS created default role `OrganizationAccountAccessRole`](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html)
     * When an account is created within an organization, AWS will create an `OrganizationAccountAccessRole` [for account management](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html), which Sysdig Secure for Cloud will use for member-account provisioning and role assuming.
     * However, when the account is invited into the organization, it's required to [create the role manually](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html#orgs_manage_accounts_create-cross-account-role)
       > You have to do this manually, as shown in the following procedure. This essentially duplicates the role automatically set up for created accounts. We recommend that you use the same name, OrganizationAccountAccessRole, for your manually created roles for consistency and ease of remembering.
     * If role name, `OrganizationAccountAccessRole` wants to be modified, it must be done both on the `aws` member-account provider AND input value `organizational_member_default_admin_role`

5. Provide a member **account ID for Sysdig Secure for Cloud workload** to be deployed.
   Our recommendation is for this account to be empty, so that deployed resources are not mixed up with your workload.
   This input must be provided as terraform required input value
    ```
    sysdig_secure_for_cloud_member_account_id=<ORGANIZATIONAL_SECURE_FOR_CLOUD_ACCOUNT_ID>
    ```
6. **Sysdig Secure** requirements, as input variable value with the `api-token`
    ```
    sysdig_secure_api_token=<SECURE_API_TOKEN>
    ```


## Role Summary

Role usage for this example comes as follows. Check [permissions](../../README.md#required-permissions) too

- **management account**
    - terraform aws provider: default
    - `SysdigSecureForCloudRole` will be created
        - used by Sysdig to subscribe to cloudtrail events
        - used by Sysdig, for image scanning feature, to `assumeRole` on `OrganizationAccountAccessRole` to be able to fetch image data from ECS Tasks and scan ECR hosted images
        <!--  - assuming previous role will also enable the access of cloudtrail s3 buckets when they are in a different region than were the terraform module is deployed -->
    - `SysdigCloudBench` role will be created for SecurityAudit read-only purpose, used by Sysdig to benchmark

- **member accounts**
    - terraform aws provider: 'member' aliased
        - this provider can be configured as desired, we just provide a default option
    - by default, we suggest using an assumeRole to the [AWS created default role `OrganizationAccountAccessRole`](https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html)
        - if this role does not exist provide input var `organizational_member_default_admin_role` with the role
    - `SysdigCloudBench` role will be created for SecurityAudit read-only purpose, used by Sysdig to benchmark

- **sysdig workload member account**
    - if ECS workload is deployed, `ECSTaskRole` will be used to define its permissions
        - used by Sysdig to assumeRole on management account `SysdigSecureForCloudRole` and other organizations `OrganizationAccountAccessRole`

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

provider "aws" {
  alias  = "member"
  region = "us-east-1"
  assume_role {
    role_arn = "arn:aws:iam::047409624352:role/OrganizationAccountAccessRole"
  }
}

module "secure-for-cloud_example_org-account" {
  providers = {
    aws.member = aws.member
  }

  source                                    = "../../terraform-aws-secure-for-cloud/examples/organizational-ecs"
  role_name                                 = "sameer"
  name                                      = "sameer-test"
  sysdig_secure_for_cloud_member_account_id = "047409624352"
  trusted_identity                          = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id                               = "b26e5d571ba8f8646e06ff8a8963a84b"
  org_units        = ["r-op65"]
}

```

See [inputs summary](#inputs) or module [`variables.tf`](https://github.com/sysdiglabs/terraform-aws-secure-for-cloud/blob/master/examples/organizational/variables.tf) file for more optional configuration.

To run this example you need have your [aws management-account profile configured in CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) and to execute:
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
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.0.0 |
| <a name="provider_aws.member"></a> [aws.member](#provider\_aws.member) | >= 4.0.0 |
| <a name="provider_sysdig"></a> [sysdig](#provider\_sysdig) | >= 0.5.33 |

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cloud_connector"></a> [cloud\_connector](#module\_cloud\_connector) | ../../modules/services/cloud-connector-ecs | n/a |
| <a name="module_cloudtrail"></a> [cloudtrail](#module\_cloudtrail) | ../../modules/infrastructure/cloudtrail | n/a |
| <a name="module_cspm_org"></a> [cspm\_org](#module\_cspm\_org) | ../../modules/services/trust-relationship | n/a |
| <a name="module_ecs_vpc"></a> [ecs\_vpc](#module\_ecs\_vpc) | ../../modules/infrastructure/ecs-vpc | n/a |
| <a name="module_resource_group"></a> [resource\_group](#module\_resource\_group) | ../../modules/infrastructure/resource-group | n/a |
| <a name="module_resource_group_secure_for_cloud_member"></a> [resource\_group\_secure\_for\_cloud\_member](#module\_resource\_group\_secure\_for\_cloud\_member) | ../../modules/infrastructure/resource-group | n/a |
| <a name="module_secure_for_cloud_role"></a> [secure\_for\_cloud\_role](#module\_secure\_for\_cloud\_role) | ../../modules/infrastructure/permissions/org-role-ecs | n/a |
| <a name="module_ssm"></a> [ssm](#module\_ssm) | ../../modules/infrastructure/ssm | n/a |

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.connector_ecs_task](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_caller_identity.me](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.task_assume_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_region.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/region) | data source |
| [sysdig_secure_connection.current](https://registry.terraform.io/providers/sysdiglabs/sysdig/latest/docs/data-sources/secure_connection) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_external_id"></a> [external\_id](#input\_external\_id) | Random string generated unique to a customer | `string` | n/a | yes |
| <a name="input_sysdig_secure_for_cloud_member_account_id"></a> [sysdig\_secure\_for\_cloud\_member\_account\_id](#input\_sysdig\_secure\_for\_cloud\_member\_account\_id) | organizational member account where the secure-for-cloud workload is going to be deployed | `string` | n/a | yes |
| <a name="input_trusted_identity"></a> [trusted\_identity](#input\_trusted\_identity) | The name of sysdig trusted identity | `string` | n/a | yes |
| <a name="input_cloudtrail_is_multi_region_trail"></a> [cloudtrail\_is\_multi\_region\_trail](#input\_cloudtrail\_is\_multi\_region\_trail) | true/false whether the created cloudtrail will ingest multi-regional events. testing/economization purpose. | `bool` | `true` | no |
| <a name="input_cloudtrail_kms_enable"></a> [cloudtrail\_kms\_enable](#input\_cloudtrail\_kms\_enable) | true/false whether the created cloudtrail should deliver encrypted events to s3 | `bool` | `true` | no |
| <a name="input_cloudtrail_s3_bucket_expiration_days"></a> [cloudtrail\_s3\_bucket\_expiration\_days](#input\_cloudtrail\_s3\_bucket\_expiration\_days) | Number of days that the logs will persist in the bucket | `number` | `5` | no |
| <a name="input_connector_ecs_task_role_name"></a> [connector\_ecs\_task\_role\_name](#input\_connector\_ecs\_task\_role\_name) | Name for the ecs task role. This is only required to resolve cyclic dependency with organizational approach | `string` | `"organizational-ECSTaskRole"` | no |
| <a name="input_ecs_cluster_name"></a> [ecs\_cluster\_name](#input\_ecs\_cluster\_name) | Name of a pre-existing ECS (elastic container service) cluster. If defaulted, a new ECS cluster/VPC/Security Group will be created. If specified all three parameters `ecs_cluster_name`, `ecs_vpc_id` and `ecs_vpc_subnets_private_ids` are required. ECS location will/must be within the `sysdig_secure_for_cloud_member_account_id` parameter accountID | `string` | `"create"` | no |
| <a name="input_ecs_task_cpu"></a> [ecs\_task\_cpu](#input\_ecs\_task\_cpu) | Amount of CPU (in CPU units) to reserve for cloud-connector task | `string` | `"256"` | no |
| <a name="input_ecs_task_memory"></a> [ecs\_task\_memory](#input\_ecs\_task\_memory) | Amount of memory (in megabytes) to reserve for cloud-connector task | `string` | `"512"` | no |
| <a name="input_ecs_vpc_id"></a> [ecs\_vpc\_id](#input\_ecs\_vpc\_id) | ID of the VPC where the workload is to be deployed. If defaulted a new VPC will be created. If specified all three parameters `ecs_cluster_name`, `ecs_vpc_id` and `ecs_vpc_subnets_private_ids` are required | `string` | `"create"` | no |
| <a name="input_ecs_vpc_region_azs"></a> [ecs\_vpc\_region\_azs](#input\_ecs\_vpc\_region\_azs) | List of Availability Zones for ECS VPC creation. e.g.: ["apne1-az1", "apne1-az2"]. If defaulted, two of the default 'aws\_availability\_zones' datasource will be taken | `list(string)` | `[]` | no |
| <a name="input_ecs_vpc_subnets_private_ids"></a> [ecs\_vpc\_subnets\_private\_ids](#input\_ecs\_vpc\_subnets\_private\_ids) | List of VPC subnets where workload is to be deployed. If defaulted new subnets will be created within the VPC. A minimum of two subnets is suggested. If specified all three parameters `ecs_cluster_name`, `ecs_vpc_id` and `ecs_vpc_subnets_private_ids` are required. | `list(string)` | `[]` | no |
| <a name="input_existing_cloudtrail_config"></a> [existing\_cloudtrail\_config](#input\_existing\_cloudtrail\_config) | Optional block. If not set, a new cloudtrail, sns and sqs resources will be created<br/><br>If there's an existing cloudtrail, input one of the Optional 1/2/3 blocks.<br><ul><br>  <li>cloudtrail\_s3\_arn: Optional 1. ARN of a pre-existing cloudtrail\_sns s3 bucket. Used together with `cloudtrail_sns_arn`, `cloudtrail_s3_arn`. If it does not exist, it will be inferred from create cloudtrail"</li><br>  <li>cloudtrail\_sns\_arn: Optional 1. ARN of a pre-existing cloudtrail\_sns. Used together with `cloudtrail_sns_arn`, `cloudtrail_s3_arn`. If it does not exist, it will be inferred from created cloudtrail. Providing an ARN requires permission to SNS:Subscribe, check ./modules/infrastructure/cloudtrail/sns\_permissions.tf block</li><br>  <li>cloudtrail\_s3\_role\_arn: Optional 2. ARN of the role to be assumed for S3 access. This role must be in the same account of the S3 bucket. Currently this setup is not compatible with organizational scanning feature</li><br>  <li>cloudtrail\_s3\_sns\_sqs\_arn: Optional 3. ARN of the queue that will ingest events forwarded from an existing cloudtrail\_s3\_sns</li><br>  <li>cloudtrail\_s3\_sns\_sqs\_url: Optional 3. URL of the queue that will ingest events forwarded from an existing cloudtrail\_s3\_sns<</li><br></ul> | <pre>object({<br>    cloudtrail_s3_arn         = optional(string)<br>    cloudtrail_sns_arn        = optional(string)<br>    cloudtrail_s3_role_arn    = optional(string)<br>    cloudtrail_s3_sns_sqs_arn = optional(string)<br>    cloudtrail_s3_sns_sqs_url = optional(string)<br>  })</pre> | <pre>{<br>  "cloudtrail_s3_arn": "create",<br>  "cloudtrail_s3_role_arn": null,<br>  "cloudtrail_s3_sns_sqs_arn": null,<br>  "cloudtrail_s3_sns_sqs_url": null,<br>  "cloudtrail_sns_arn": "create"<br>}</pre> | no |
| <a name="input_name"></a> [name](#input\_name) | Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances | `string` | `"sfc"` | no |
| <a name="input_org_units"></a> [org\_units](#input\_org\_units) | Org unit id to install cspm | `set(string)` | `[]` | no |
| <a name="input_organizational_member_default_admin_role"></a> [organizational\_member\_default\_admin\_role](#input\_organizational\_member\_default\_admin\_role) | Default role created by AWS for management-account users to be able to admin member accounts.<br/>https://docs.aws.amazon.com/organizations/latest/userguide/orgs_manage_accounts_access.html | `string` | `"OrganizationAccountAccessRole"` | no |
| <a name="input_role_name"></a> [role\_name](#input\_role\_name) | Role name for cspm | `string` | `"sfc-cspm-role"` | no |
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
