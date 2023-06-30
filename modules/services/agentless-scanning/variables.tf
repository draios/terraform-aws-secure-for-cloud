variable "external_id" {
  description = "Random string generated unique to a customer"
  type        = string
}

variable "trusted_identity" {
  type        = string
  description = "The name of sysdig trusted identity"
}

variable "kms_key_deletion_window" {
  description = "Deletion window for shared KMS key"
  type        = number
  default     = 7
}

variable "name" {
  description = "The name of the installation. Assigned to most child resource(s)"
  type        = string
}

variable "tags" {
  type        = map(string)
  description = "sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"
  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}
