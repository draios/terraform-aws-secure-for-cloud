variable "external_id" {
  description = "Random string generated unique to a customer"
  type        = string
}

variable "trusted_identity" {
  type        = string
  description = "The name of sysdig trusted identity"
}

variable "agentless_account_id" {
  type        = string
  description = "The identifier of the account that will receive volume snapshots"
  default     = "878070807337"
}

variable "kms_key_deletion_window" {
  description = "Deletion window for shared KMS key"
  type        = number
  default     = 7
}

variable "name" {
  description = "The name of the installation. Assigned to most child resource(s)"
  type        = string
  default     = "sysdig-secure-scanning"
}

variable "tags" {
  type        = map(string)
  description = "sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"
  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}
variable "deploy_global_resources" {
  description = "(Optional) Set this field to 'true' to deploy Agentless Scanning to an AWS Organization (Or specific OUs)"
  type        = bool
  default     = false
}

variable "kms_key_alias" {
  description = "The alias of the KMS key used to encrypt the data plane secrets"
  type        = string
  default     = "sysdig-secure-scanning"
}

variable "primary_key" {
  description = "The primary KMS key deployed in global region"
  type = object({
    id  = string
    arn = string
  })
  default = {
    id  = ""
    arn = ""
  }
}

variable "is_organizational" {
  description = "(Optional) Set this field to 'true' to deploy Agentless Scanning to an AWS Organization (Or specific OUs)"
  type        = bool
  default     = false
}

variable "org_units" {
  description = "(Optional) List of Organization Unit IDs in which to setup Agentless Scanning. By default, Agentless Scanning will be setup in all accounts within the Organization. This field is ignored if `is_organizational = false`"
  type        = set(string)
  default     = []
}