## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "metastore_id" {
  type        = string
  description = "ID of the metastore assigned to the workspace. Pass the assignment module's ready_metastore_id to preserve ordering."
  nullable    = false

  validation {
    condition     = trimspace(var.metastore_id) != "" && var.metastore_id == trimspace(var.metastore_id)
    error_message = "metastore_id must be nonblank and have no leading or trailing whitespace."
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "grants" {
  type = list(object({
    principal  = string
    privileges = set(string)
  }))
  description = "Complete authoritative metastore grants, with one entry per principal. An empty list revokes existing grants rather than skipping management."
  default     = []
  nullable    = false

  validation {
    condition = alltrue([
      for grant in var.grants : try(
        trimspace(grant.principal) != "" && grant.principal == trimspace(grant.principal),
        false
      )
    ])
    error_message = "Each grant must have a nonblank principal with no leading or trailing whitespace."
  }

  validation {
    condition = alltrue([
      for grant in var.grants : try(
        length(grant.privileges) > 0 && alltrue([
          for privilege in grant.privileges : try(
            trimspace(privilege) != "" && privilege == trimspace(privilege),
            false
          )
        ]),
        false
      )
    ])
    error_message = "Each grant must have a nonempty privileges set containing only nonblank strings with no leading or trailing whitespace."
  }

  validation {
    condition     = try(length(distinct([for grant in var.grants : grant.principal])) == length(var.grants), false)
    error_message = "Each principal must appear only once in grants; combine its privileges into one entry."
  }
}
