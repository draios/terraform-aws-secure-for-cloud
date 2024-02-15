variable "external_id" {
  description = "Random string generated unique to a customer"
  type        = string
}

variable "trusted_identity" {
  type        = string
  description = "The name of sysdig trusted identity"
}

variable "name" {
  description = "The name of the installation. Assigned to most child resource(s)"
  type        = string
  default     = "sysdig-workload-scanning"
}

variable "tags" {
  type        = map(string)
  description = "sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"
  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}

variable "deploy_global_resources" {
  description = "(Optional) Set this field to 'true' to deploy Agentless Workload Scanning when deploying to the main region (Non Organization Setup)"
  type        = bool
  default     = false
}

variable "is_organizational" {
  description = "(Optional) Set this field to 'true' to deploy Agentless Workload Scanning to an AWS Organization (Or specific OUs)"
  type        = bool
  default     = false
}

variable "org_units" {
  description = "(Optional) List of Organization Unit IDs in which to setup Agentless Workload Scanning. By default, Agentless Workload Scanning will be setup in all accounts within the Organization. This field is ignored if `is_organizational = false`"
  type        = set(string)
  default     = []
}

variable "role_arn" {
  description = "(Optional) The ARN of the role to be associated with the with regional resources. Must be set if deploy_global_resources is false"
  type        = string
  default     = ""
}
