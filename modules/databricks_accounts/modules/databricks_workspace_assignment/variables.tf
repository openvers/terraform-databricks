## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "principal_id" {
  type        = string
  description = "Databricks account user, group or service principal SCIM ID. Accepts the ID output from shared identity modules; converts it to the provider's integer field. Not a cloud identity or application/client ID."
  nullable    = false

  validation {
    condition = try(
      can(regex("^[1-9][0-9]*$", var.principal_id)) &&
      tonumber(var.principal_id) <= 9223372036854775807,
      false
    )
    error_message = "principal_id must be a positive decimal Databricks SCIM ID within the signed 64-bit integer range."
  }
}

variable "workspace_id" {
  type        = number
  description = "Positive integer Databricks workspace ID, not a cloud resource ID."
  nullable    = false

  validation {
    condition = (
      var.workspace_id > 0 &&
      var.workspace_id == floor(var.workspace_id) &&
      var.workspace_id <= 9223372036854775807
    )
    error_message = "workspace_id must be a positive integer Databricks workspace ID within the signed 64-bit integer range."
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "permission" {
  type        = string
  description = "Workspace permission for this assignment: USER for basic access or explicitly selected ADMIN for workspace administrative access."
  default     = "USER"
  nullable    = false

  validation {
    condition     = contains(["USER", "ADMIN"], var.permission)
    error_message = "permission must be USER or ADMIN; administrative access must be selected explicitly."
  }
}
