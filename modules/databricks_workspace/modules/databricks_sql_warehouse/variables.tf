variable "warehouse_name" {
  type        = string
  description = "SQL warehouse name."
  nullable    = false
}

variable "config" {
  description = "SQL warehouse sizing, availability, and authoritative complete ACL when any permission map is nonempty. Keys are existing workspace group names, usernames (emails), or service-principal application IDs. Callers must include all intended grants, including explicit administrator CAN_MANAGE grants. IS_OWNER is unsupported; the provider may make the authenticated principal the implicit owner when no owner is specified."

  type = object({
    cluster_size                  = optional(string, "Small")
    min_num_clusters              = optional(number, 1)
    max_num_clusters              = optional(number, 1)
    auto_stop_mins                = optional(number, 15)
    enable_photon                 = optional(bool, true)
    enable_serverless_compute     = optional(bool, false)
    warehouse_type                = optional(string, "PRO")
    tags                          = optional(map(string), {})
    group_permissions             = optional(map(string), {})
    user_permissions              = optional(map(string), {})
    service_principal_permissions = optional(map(string), {})
  })

  default  = {}
  nullable = false

  validation {
    condition = (
      var.config.min_num_clusters >= 1 &&
      var.config.max_num_clusters >= var.config.min_num_clusters &&
      var.config.max_num_clusters <= 40 &&
      floor(var.config.min_num_clusters) == var.config.min_num_clusters &&
      floor(var.config.max_num_clusters) == var.config.max_num_clusters
    )
    error_message = "Cluster counts must be integers satisfying 1 <= min_num_clusters <= max_num_clusters <= 40."
  }

  validation {
    condition = (
      contains(["CLASSIC", "PRO"], var.config.warehouse_type) &&
      (
        !var.config.enable_serverless_compute ||
        var.config.warehouse_type == "PRO"
      )
    )
    error_message = "warehouse_type must be CLASSIC or PRO. Serverless requires PRO."
  }

  validation {
    condition = alltrue([
      for permission in concat(
        values(var.config.group_permissions),
        values(var.config.user_permissions),
        values(var.config.service_principal_permissions)
      ) :
      contains(["CAN_VIEW", "CAN_USE", "CAN_MONITOR", "CAN_MANAGE"], permission)
    ])
    error_message = "Group, user, and service-principal permissions must be CAN_VIEW, CAN_USE, CAN_MONITOR, or CAN_MANAGE; IS_OWNER is unsupported."
  }

  validation {
    condition = alltrue([
      for principal in concat(
        keys(var.config.group_permissions),
        keys(var.config.user_permissions),
        keys(var.config.service_principal_permissions)
      ) :
      trimspace(principal) != "" && trimspace(principal) == principal
    ])
    error_message = "Permission map keys must be nonblank principal identifiers without leading or trailing whitespace."
  }
}

variable "group_names" {
  description = "Workspace group display names keyed by logical group keys."
  type        = map(string)
  nullable    = false
}