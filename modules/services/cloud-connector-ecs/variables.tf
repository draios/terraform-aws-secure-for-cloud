variable "secure_api_token_secret_name" {
  type        = string
  description = "Sysdig Secure API token SSM parameter name"
}

variable "sysdig_secure_api_token" {
  description = "Api token for deployment"
  default     = ""
}

variable "sysdig_secure_endpoint" {
  description = "Backend url where results are sent"
  default     = ""
}

variable "region" {
  description = "AWS region where resources are deployed"
  default     = ""
}

#
# cloudtrail configuration
#
variable "cloudtrail_sns_arn" {
  type        = string
  default     = "create"
  description = "ARN of a pre-existing cloudtrail_sns. If defaulted, a new cloudtrail will be created. If specified, sysdig deployment account and region must match with the specified SNS"
}

variable "cloudtrail_is_multi_region_trail" {
  type        = bool
  default     = true
  description = "true/false whether cloudtrail will ingest multiregional events"
}

variable "cloudtrail_kms_enable" {
  type        = bool
  default     = true
  description = "true/false whether cloudtrail delivered events to S3 should persist encrypted"
}

variable "cloudtrail_s3_bucket_expiration_days" {
  type        = number
  default     = 5
  description = "Number of days that the logs will persist in the bucket"
}

#
# ecs, security group,  vpc
#

variable "ecs_cluster_name" {
  type        = string
  description = "Name of a pre-existing ECS (elastic container service) cluster"
  default     = ""
}

variable "ecs_vpc_id" {
  type        = string
  description = "ID of the VPC where the workload is to be deployed."
  default     = ""
}

variable "ecs_vpc_subnets_private_ids" {
  type        = list(string)
  description = "List of VPC subnets where workload is to be deployed."
  default     = []
}

variable "ecs_vpc_region_azs" {
  type        = list(string)
  description = "List of Availability Zones for ECS VPC creation. e.g.: [\"apne1-az1\", \"apne1-az2\"]. If defaulted, two of the default 'aws_availability_zones' datasource will be taken"
  default     = []
}

#
# cloudtrail parametrization
#

variable "existing_cloudtrail_config" {
  type = object({
    cloudtrail_sns_arn        = optional(string)
    cloudtrail_s3_sns_sqs_arn = optional(string)
    cloudtrail_s3_sns_sqs_url = optional(string)
  })
  default = {
    cloudtrail_sns_arn        = "create"
    cloudtrail_s3_sns_sqs_arn = null
    cloudtrail_s3_sns_sqs_url = null
  }

  description = <<-EOT
    Optional block. If not set, a new cloudtrail, sns and sqs resources will be created<br/>
    If there's an existing cloudtrail, input mandatory attributes, and one of the 1 or 2 labeled optionals.
    <ul>
      <li>cloudtrail_sns_arn: Optional 1. ARN of a cloudtrail-sns topic. If specified, deployment region must match Cloudtrail S3 bucket region</li>
      <li>cloudtrail_s3_sns_sqs_arn: Optional 2. ARN of the queue that will ingest events forwarded from an existing cloudtrail_s3_sns</li>
      <li>cloudtrail_s3_sns_sqs_url: Optional 2. URL of the queue that will ingest events forwarded from an existing cloudtrail_s3_sns<br/>sqs:ReceiveMessage and sqs:DeleteMessage permissions have to be provided to the compute role</li>
    </ul>
  EOT
}



#---------------------------------
# optionals - with default
#---------------------------------

#
# module composition
#

variable "is_organizational" {
  type        = bool
  default     = false
  description = "true/false whether `organizational_config` should be used to handle organizational setup"
}


variable "organizational_config" {
  type = object({
    sysdig_secure_for_cloud_role_arn = string
    organizational_role_per_account  = string
    connector_ecs_task_role_name     = string
  })
  default = {
    sysdig_secure_for_cloud_role_arn = null
    organizational_role_per_account  = null
    connector_ecs_task_role_name     = null
  }

  description = <<-EOT
    organizational_config. following attributes must be given
    <ul>
      <li>`sysdig_secure_for_cloud_role_arn` for cloud-connector assumeRole in order to read cloudtrail s3 events</li>
      <li>`connector_ecs_task_role_name` which has been granted trusted-relationship over the secure_for_cloud_role</li>
      <li>`organizational_role_per_account` is the name of the organizational role deployed by AWS in each account of the organization. used for image-scanning only</li>
    </ul>
  EOT
}

#
# module config
#

# Configure CPU and memory in pairs.
# See: https://docs.aws.amazon.com/AmazonECS/latest/developerguide/task_definition_parameters.html#task_size
variable "ecs_task_cpu" {
  type        = string
  description = "Amount of CPU (in CPU units) to reserve for cloud-connector task"
  default     = "256"
}

variable "ecs_task_memory" {
  type        = string
  description = "Amount of memory (in megabytes) to reserve for cloud-connector task"
  default     = "512"
}

variable "connector_ecs_task_role_name" {
  type        = string
  default     = "ECSTaskRole"
  description = "Default ecs cloudconnector task role name"
}

variable "image" {
  type        = string
  default     = "quay.io/sysdig/cloud-connector:latest"
  description = "Image of the cloud connector to deploy"
}

variable "cloudwatch_log_retention" {
  type        = number
  default     = 5
  description = "Days to keep logs for CloudConnector"
}

variable "verify_ssl" {
  type        = bool
  default     = true
  description = "true/false to determine ssl verification for sysdig_secure_url"
}

variable "extra_env_vars" {
  type        = map(string)
  default     = {}
  description = "Extra environment variables for the Cloud Connector deployment"
}

#
# general
#
variable "name" {
  type        = string
  default     = "sfc-cloudconnector"
  description = "Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances"
}

variable "tags" {
  type        = map(string)
  description = "sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"
  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}
