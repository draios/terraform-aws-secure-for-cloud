variable "bucket_arn" {
  description = "(Required) The ARN of your s3 bucket associated with your Cloudtrail trail"
  type        = string
}

variable "account_id" {
  description = "(Required) The identifier of your AWS account"
  type        = string
}

variable "external_id" {
  type        = string
  description = "(Required) Random string generated unique to a customer"
}

variable "role_name" {
  description = "(Required) The name of the IAM Role that will enable access to the Cloudtrail logs"
  type        = string
  default     = "cloudtrail-s3-bucket-read-access"
}

variable "tags" {
  type        = map(string)
  description = "(Optional) Sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"

  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}

variable "trusted_identity" {
  description = "(Required) The name of Sysdig trusted identity"
  type        = string
}

