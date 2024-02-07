variable "region" {
  description = "The AWS region where clusters reside"
  type        = string
}

variable "onboard_all_clusters" {
  description = "Should all public clusters be onboarded and scanned by Sysdig"
  type        = bool
  default     = false
}

variable "clusters" {
  description = "Names of the clusters to be onboarded and scanned by Sysdig"
  type        = set(string)
}

variable "principal_arn" {
  description = "The IAM Principal ARN which will access the EKS cluster"
  type        = string
}
