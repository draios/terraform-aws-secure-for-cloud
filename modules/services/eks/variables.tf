// Values required to create access entries
variable "role_name" {
  description = "(Required) IAM role that Sysdig will assume to access the EKS clusters"
  type        = string
}

variable "onboard_all_clusters" {
  description = "(Optional) Set the value to true if all public clusters (API and API_AND_CONFIG_MAP-type clusters) should be scanned by Sysdig. Only the clusters having authentication mode set to either API or API_AND_CONFIG_MAP will be onboarded."
  type        = bool
  default     = false
}

variable "clusters" {
  description = "(Optional) Please list the clusters to be scanned by Sysdig (when 'onboard_all_clusters' is set to false, only the clusters specified here will be scanned). The clusters must have authentication mode set to either API or API_AND_CONFIG_MAP to be onboarded."
  type        = set(string)
  default     = []
}

// Values required to create the ECR role
variable "deploy_global_resources" {
  description = "(Optional) Setting this field to 'true' creates an IAM role that allows Sysdig to pull ECR images."
  type        = bool
  default     = false
}

variable "trusted_identity" {
  type        = string
  description = "(Optional) This value should be provided by Sysdig. The field refers to Sysdig's IAM role that will be authorized to pull ECR images."
  default     = null
}

variable "name" {
  description = "(Optional) This value should be provided by Sysdig. The field refers to an installation name, which will also be used to name the IAM role that grants access to pull ECR images."
  type        = string
  default     = null
}

variable "external_id" {
  description = "(Optional) This value should be provided by Sysdig. External ID is optional information that you can use in an IAM role trust policy to designate who in Sysdig can assume the role."
  type        = string
  default     = null
}

variable "tags" {
  type        = map(string)
  description = "(Optional) This value should be provided by Sysdig. Tags that will be associated with the IAM role."
  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}

output "validate_deploy_global_resources" {
  value = null
  precondition {
    condition     = (var.deploy_global_resources && var.external_id != null)
    error_message = "Please provide external_id or set deploy_global_resources to false."
  }
  precondition {
    condition     = (var.deploy_global_resources && var.name != null)
    error_message = "Please provide name or set deploy_global_resources set to false."
  }
  precondition {
    condition     = (var.deploy_global_resources && var.trusted_identity != null)
    error_message = "Please provide trusted_identity or set deploy_global_resources to false."
  }
}
