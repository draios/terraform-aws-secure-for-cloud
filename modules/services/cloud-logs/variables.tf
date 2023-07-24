variable "bucket_name" {
  description = "(Required) The name of your s3 bucket associated with your Clloudtrail trail"
  type        = string
}

variable "external_id" {
  type        = string
  description = "(Required) Random string generated unique to a customer"
}

variable "region" {
  description = "(Optional) Default region for resource creation"
  type        = string
  # This default was inherited from the previous trust-relationship config and related to
  # organization mode. Does this still hold?
  default = "eu-central-1"
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
