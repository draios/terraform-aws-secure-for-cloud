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
  default     = "sfc-cspm-role"
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
  default     = "eu-central-1"
  description = "Default region for resource creation in organization mode"
}

variable "provision_caller_account" {
  type        = bool
  default     = true
  description = "true/false whether to provision the aws provider account (if is_organizational=true management account, if is_organizational=false it will depend on the provider setup on the caller module"
}

variable "tags" {
  type        = map(string)
  description = "sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"

  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}
