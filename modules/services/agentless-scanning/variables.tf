variable "external_id" {
  description = "Random string generated unique to a customer"
  type        = string
}

variable "sysdig_be_account_id" {
  description = "Sysdig BE where the Customer's tenancy is hosted"
  type        = string
}

variable "kms_key_deletion_window" {
  description = "Deletion window for shared KMS key"
  type        = number
  default     = 7
}
