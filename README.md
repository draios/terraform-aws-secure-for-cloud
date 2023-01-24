# Sysdig Secure for Cloud in AWS

Terraform module that deploys the [**Sysdig Secure for Cloud** stack in **AWS**](https://docs.sysdig.com/en/docs/installation/sysdig-secure-for-cloud/deploy-sysdig-secure-for-cloud-on-aws).
<br/>

Provides unified threat-detection, compliance, forensics and analysis through these major components:

* **[CSPM](https://docs.sysdig.com/en/docs/sysdig-secure/benchmarks/)**: It evaluates periodically your cloud configuration, using Cloud Custodian, against some benchmarks and returns the results and remediation you need to fix. Managed through `trust-relationship` module. <br/>

* **[CIEM](https://docs.sysdig.com/en/docs/sysdig-secure/posture/)**: Permissions and Entitlements management. Requires BOTH modules  `cloud-connector` and `cspm`. <br/>

* **[Cloud Threat Detection](https://docs.sysdig.com/en/docs/sysdig-secure/insights/)**: Tracks abnormal and suspicious activities in your cloud environment based on Falco language. Managed through `cloud-connector` module. <br/>


For other Cloud providers check: [GCP](https://github.com/draios/terraform-google-secure-for-cloud), [Azure](https://github.com/draios/terraform-azurerm-secure-for-cloud)

<br/>

## Usage

There are several ways to deploy this in you AWS infrastructure:

### - Single-Account

Sysdig workload will be deployed in the same account where user's resources will be watched.<br/>
More info in [`./examples/single-account-ecs`](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/examples/single-account-ecs)

![single-account diagram](https://raw.githubusercontent.com/draios/terraform-aws-secure-for-cloud/7d142829a701ce78f13691a4af4be373625e7ee2/examples/single-account/diagram-single.png)


### - Single-Account with a pre-existing Kubernetes Cluster

If you already own a Kubernetes Cluster on AWS, you can use it to deploy Sysdig Secure for Cloud, instead of default ECS cluster.<br/>
More info in [`./examples/single-account-k8s`](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/examples/single-account-k8s)

### - Organizational

Using an organizational configuration Cloudtrail.<br/>
More info in [`./examples/organizational-ecs`](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/examples/organizational-ecs)

![organizational diagram](https://raw.githubusercontent.com/draios/terraform-aws-secure-for-cloud/5b7cf5e8028b3177536c9c847020ad6319342b44/examples/organizational/diagram-org.png)

### - Self-Baked

If no [examples](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/examples) fit your use-case, be free to call desired modules directly.

In this use-case we will ONLY deploy cspm, into the target account, calling modules directly

```terraform
provider "aws" {}

module "secure-for-cloud_example_single-account" {
  source           = "../../terraform-aws-secure-for-cloud/modules/services/trust-relationship"
  role_name        = "sameer-role1"
  trusted_identity = "arn:aws:iam::064689838359:role/us-east-1-integration01-secure-assume-role"
  external_id      = "b26e5d571ba8f8646e06ff8a8963a84b"
}

output "role_arn" {
  value       = module.secure-for-cloud_example_single-account.cspm_role_arn
  description = "ARN of cspm role"
}


```
See [inputs summary](#inputs) or main [module `variables.tf`](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/variables.tf) file for more optional configuration.

To run this example you need have your [aws master-account profile configured in CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-profiles.html) and to execute:
```terraform
$ terraform init
$ terraform plan
$ terraform apply
```

Notice that:
* This example will create resources that cost money.<br/>Run `terraform destroy` when you don't need them anymore
* All created resources will be created within the tags `product:sysdig-secure-for-cloud`, within the resource-group `sysdig-secure-for-cloud`

<br/><br/>

## Forcing Events

**Threat Detection**

Choose one of the rules contained in the `AWS Best Practices` policy and execute it in your AWS account.

ex.: 'Delete Bucket Public Access Block' can be easily tested going to an
`S3 bucket > Permissions > Block public access (bucket settings) > edit >
uncheck 'Block all public access'`

Remember that in case you add new rules to the policy you need to give it time to propagate the changes.

In the `cloud-connector` logs you should see similar logs to these
> A public access block for a bucket has been deleted (requesting  user=OrganizationAccountAccessRole, requesting IP=x.x.x.x, AWS  region=eu-central-1, bucket=***

If that's not working as expected, some other questions can be checked
- are events consumed in the sqs queue, or are they pending?
- are events being sent to sns topic?

<br/>

## Troubleshooting

### Q: I'm not able to see Cloud Infrastructure Entitlements Management (CIEM) results
A: Make sure you installed both [cspm](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/modules/services/cspm) and [cloud-connector](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/modules/services/cloud-connector) modules

### Q: How to iterate cloud-connector modification testing
A: Build a custom docker image of cloud-connector `docker build . -t <DOCKER_IMAGE> -f ./build/cloud-connector/Dockerfile` and upload it to any registry (like dockerhub).
Modify the [var.image](https://github.com/draios/terraform-aws-secure-for-cloud/tree/master/modules/services/cloud-connector/variables.tf) variable to point to your image and deploy


### Q: How can I iterate ECS modification testing
A: After applying your modifications (vía terraform for example) restart the service
  ```
  $ aws ecs update-service --force-new-deployment --cluster sysdig-secure-for-cloud-ecscluster --service sysdig-secure-for-cloud-cloudconnector --profile <AWS_PROFILE>
  ```
For the AWS_PROFILE, set your `~/.aws/config` to impersonate
  ```
  [profile secure-for-cloud]
  region=eu-central-1
  role_arn=arn:aws:iam::<AWS_MANAGEMENT_ORGANIZATION_ACCOUNT>:role/OrganizationAccountAccessRole
  source_profile=<AWS_MANAGEMENT_ACCOUNT_PROFILE>
  ```

<br/><br/>
## Authors

Module is maintained and supported by [Sysdig](https://sysdig.com).

## License

Apache 2 Licensed. See LICENSE for full details.
