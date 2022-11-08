

#---------------------------------
# optionals - with defaults
#---------------------------------
variable "sysdig_secure_api_token" {
  description = "Api token for deployment"
  default     = ""
}

variable "sysdig_secure_endpoint" {
  description = "Backend url where results are sent"
  default     = ""
}

variable "region" {
  description = "AWS region where resources are deployed"
  default     = ""
}

#
# trust-relationship configuration
#
variable "role_name" {
  type        = string
  description = "Role name for cspm"
  default     = "sfc-cspm-role"
}

#
# general
#

variable "name" {
  type        = string
  description = "Name to be assigned to all child resources. A suffix may be added internally when required. Use default value unless you need to install multiple instances"
  default     = "sfc"
}

variable "tags" {
  type        = map(string)
  description = "sysdig secure-for-cloud tags. always include 'product' default tag for resource-group proper functioning"
  default = {
    "product" = "sysdig-secure-for-cloud"
  }
}
