variable "target_event_bus_arn" {
  description = "(Required) The ARN of Sysdig's event bus that will receive events from your account"
  type        = string
}

variable "is_organizational" {
  description = "(Optional) Set this field to 'true' to deploy EventBridge to an AWS Organization (Or specific OUs)"
  type        = bool
  default     = false
}

variable "deploy_global_resources" {
  description = "(Optional) Set this field to 'true' to deploy EventBridge to an AWS Organization (Or specific OUs)"
  type        = bool
  default     = false
}

variable "org_units" {
  description = "(Optional) List of Organization Unit IDs in which to setup EventBridge. By default, EventBridge will be setup in all accounts within the Organization. This field is ignored if `is_organizational = false`"
  type        = set(string)
  default     = []
}

variable "regions" {
  description = "(Optional) List of regions in which to setup EventBridge. By default, current region is selected"
  type        = set(string)
  default     = []
}

variable "stackset_admin_role_arn" {
  description = "(Optional) stackset admin role to run SELF_MANAGED stackset"
  type        = string
  default     = ""
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

variable "role_arn" {
  description = "(Optional) IAM role created for event-bridge. If already created value is needed to be passed"
  type        = string
  default     = ""
}

variable "trusted_identity" {
  type        = string
  description = "The name of sysdig trusted identity"
}

variable "external_id" {
  type        = string
  description = "Random string generated unique to a customer"
}

variable "rule_state" {
  type        = string
  description = "State of the rule. When state is ENABLED, the rule is enabled for all events except those delivered by CloudTrail. To also enable the rule for events delivered by CloudTrail, set state to ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS."
  default     = "ENABLED_WITH_ALL_CLOUDTRAIL_MANAGEMENT_EVENTS"
}

variable "event_pattern" {
  description = "Event pattern for CloudWatch Event Rule"
  type        = string
  default     = <<EOF
{
  "detail-type": [
    "AWS API Call via CloudTrail",
    "AWS Console Sign In via CloudTrail",
    "AWS Service Event via CloudTrail",
    "Object Access Tier Changed",
    "Object ACL Updated",
    "Object Created",
    "Object Deleted",
    "Object Restore Completed",
    "Object Restore Expired",
    "Object Restore Initiated",
    "Object Storage Class Changed",
    "Object Tags Added",
    "Object Tags Deleted",
    "GuardDuty Finding"
  ]
}
EOF
}

variable "timeout" {
  type        = string
  description = "Default timeout values for create, update, and delete operations"
  default     = "30m"
}

variable "mgt_stackset" {
  description = "(Optional) Indicates if the management stackset should be deployed"
  type        = bool
  default     = true
}

variable "failure_tolerance_percentage" {
  type        = number
  description = "The percentage of accounts, per Region, for which stack operations can fail before AWS CloudFormation stops the operation in that Region"
  default     = 90
}