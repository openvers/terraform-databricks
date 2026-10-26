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
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

