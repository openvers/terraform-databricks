## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "group_name" {
  type        = string
  description = "Databricks Group/Team Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "members" {
  type        = map(string)
  description = <<-EOT
    Databricks SCIM member IDs keyed by plan-known logical names, for example
    { pipeline = module.pipeline.databricks_service_principal_id }.
    Member ID values may be computed; keys and map membership must be known during planning.
    Supports users, service principals and groups; IDs are Databricks identity IDs, not cloud-provider IDs.
    Use either this map or the legacy member_ids list, not both.
    Migrating existing memberships requires caller-specific moved blocks or terraform state mv from
    databricks_group_member.this[index] to databricks_group_member.keyed["logical-name"].
    Preserve the same group/member pairs during migration; no automatic state moves are performed.
  EOT
  default     = {}
  nullable    = false

  validation {
    condition = alltrue([
      for key, member_id in var.members :
      length(trimspace(key)) > 0 && key == trimspace(key) &&
      length(regexall("[\t\r\n]", key)) == 0 &&
      try(length(trimspace(member_id)) > 0 && member_id == trimspace(member_id) && length(regexall("[\t\r\n]", member_id)) == 0, false)
    ])
    error_message = "Membership keys and Databricks member IDs must be nonempty, without surrounding whitespace or tab/newline characters."
  }

  validation {
    condition     = length(distinct(values(var.members))) == length(var.members)
    error_message = "Each members entry must reference a unique Databricks member ID; do not manage the same membership under multiple keys."
  }
}
