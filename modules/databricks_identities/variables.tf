## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_groups" {
  description = "Account groups, memberships, and workspace entitlements/assignments. Assignment keys must be plan-known canonical workspace names shared across groups."

  type = map(object({
    name    = string
    members = optional(map(string), {})

    workspace_entitlements = optional(object({
      workspace_access           = optional(bool, false)
      databricks_sql_access      = optional(bool, false)
      allow_cluster_create       = optional(bool, false)
      allow_instance_pool_create = optional(bool, false)
    }))

    workspace_assignments = optional(map(object({
      workspace_id = number
      permission   = optional(string, "USER")
    })), {})
  }))

  default  = {}
  nullable = false

  validation {
    condition = alltrue(flatten([
      for group in values(var.databricks_groups) : [
        for assignment in values(group.workspace_assignments) :
        contains(["USER", "ADMIN"], assignment.permission)
      ]
    ]))
    error_message = "Workspace assignment permission must be USER or ADMIN."
  }

  validation {
    condition     = !contains(keys(var.databricks_groups), "__default_admin")
    error_message = "The __default_admin group key is reserved for the module-managed default group."
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "default_service_principal_name" {
  description = "Display name of the default account service principal."
  type        = string
  default     = "terraform-default-service-principal"
}

variable "default_admin_group_name" {
  description = "Display name of the default account group."
  type        = string
  default     = "terraform-default-admins"
}
