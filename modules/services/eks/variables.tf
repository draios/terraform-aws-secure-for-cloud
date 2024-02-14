variable "onboard_all_clusters" {
  description = "Set the value to true if all public clusters should be scanned by Sysdig"
  type        = bool
  default     = false
}

variable "clusters" {
  description = "Please list the clusters to be scanned by Sysdig (when 'onboard_all_clusters' is set to false, only the clusters specified here will be scanned)"
  type        = set(string)
  default     = []
}

variable "role_name" {
  description = "IAM role that Sysdig will assume to access the EKS clusters"
  type        = string
}
