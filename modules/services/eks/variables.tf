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

variable "principal_arn" {
  description = "Sysdig's IAM Principal ARN which will access the EKS clusters"
  type        = string
}
