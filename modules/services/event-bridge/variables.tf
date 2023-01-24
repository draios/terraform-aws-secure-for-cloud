variable "target_event_bus_arn" {
  description = "(Required) The ARN of Sysdig's event bus that will receive events from your account"
  type        = string
}

variable "target_dead_letter_queue_arn" {
  description = "(Optional) The ARN of Sysdig's SQS Queue that will act as a dead letter queue for events from your account"
  type        = string
  default     = ""
}

variable "is_organizational" {
  description = "(Optional) Set this field to 'true' to deploy EventBridge to an AWS Organization (Or specific OUs)"
  type        = bool
  default     = false
}

variable "provision_management_account" {
  type        = bool
  default     = true
  description = "(Optional) Set this field to `true` to deploy EventBridge to the management account. By default, the management account will be instrumented. This field is ignored if `is_organizational = false`"
}

variable "organization_units" {
  description = "(Optional) List of Organization Unit IDs in which to setup EventBridge. By default, EventBridge will be setup in all accounts within the Organization. This field is ignored if `is_organizational = false`"
  type        = set(string)
  default     = []
}

variable "name" {
  description = "(Optional) Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances"
  type        = string
  default     = "sysdig"
}

variable "tags" {
  description = "(Optional) Tags to be attached to all Sysdig resources."
  type        = map(string)
  default = {
    "product" = "sysdig"
  }
}
