#---------------------------------
# optionals - with default
#---------------------------------

variable "trusted_identity" {
  type        = string
  description = "The name of sysdig trusted identity"
}

variable "external_id" {
  type        = string
  description = "Random string generated unique to a customer"
}

variable "role_name" {
  type        = string
  description = "The name of the IAM Role that will be created."
  default     = "sysdig-secure"
}

variable "is_organizational" {
  type        = bool
  default     = false
  description = "true/false whether secure-for-cloud should be deployed in an organizational setup (all accounts of org) or not (only on default aws provider account)"
}

variable "org_units" {
  description = "Org unit id to install cspm"
  type        = set(string)
  default     = []
}

variable "region" {
  type        = string
  default     = ""
  description = "Default region for resource creation in organization mode"
}

variable "tags" {
  type        = map(string)
  description = "sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"

  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}

variable "timeout" {
  type        = string
  description = "Default timeout values for create, update, and delete operations"
  default     = "30m"
}

variable "failure_tolerance_percentage" {
  type        = number
  description = "The percentage of accounts, per Region, for which stack operations can fail before AWS CloudFormation stops the operation in that Region"
  default     = 90
}


variable "delegated_admin" {
  description = "Whether a delegated admin account will be used"
  type        = bool
  default     = false
}