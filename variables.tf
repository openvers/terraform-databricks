## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_catalog_config" {
  description = "Unity Catalog configuration keyed by catalog, schema, volume, file, and table names. File values are base64-encoded content."
  type = map(object({
    create     = optional(bool, true)
    comment    = optional(string)
    properties = optional(map(string), {})
    sample_data = optional(object({
      enabled = optional(bool, false)
    }), {})
    schemas = optional(map(object({
      comment    = optional(string)
      properties = optional(map(string), {})
      volumes = optional(map(object({
        volume_type      = optional(string, "MANAGED")
        storage_location = optional(string)
        storage_path     = optional(string)
        comment          = optional(string)
        files            = optional(map(string), {})
      })), {})
      tables = optional(map(object({
        cluster_key        = string
        table_type         = optional(string, "EXTERNAL")
        data_source_format = optional(string, "DELTA")
        storage_location   = string
        comment            = optional(string)
        table_columns = list(object({
          name     = string
          type     = string
          comment  = optional(string)
          nullable = optional(bool, true)
        }))
      })), {})
    })), {})
  }))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for catalog in values(var.databricks_catalog_config) :
      catalog.sample_data.enabled ? !contains([for name in keys(catalog.schemas) : lower(name)], "terraform_samples") : true
    ])
    error_message = "The terraform_samples schema is reserved when sample_data.enabled is true for its catalog."
  }

  validation {
    condition = alltrue(flatten([
      for catalog in values(var.databricks_catalog_config) : [
        for schema in values(catalog.schemas) : [
          for volume in values(schema.volumes) : (
            volume.volume_type == "MANAGED" ? volume.storage_location == null : (
              volume.volume_type == "EXTERNAL" ? (
                volume.storage_location == null ? false : trimspace(volume.storage_location) != ""
              ) : false
            )
          )
        ]
      ]
    ]))
    error_message = "Volumes must be MANAGED with no storage_location, or EXTERNAL with a non-empty storage_location."
  }

  validation {
    condition = alltrue(flatten([
      for catalog in values(var.databricks_catalog_config) : [
        for schema in values(catalog.schemas) : [
          for table in values(schema.tables) : contains(keys(var.databricks_clusters), table.cluster_key)
        ]
      ]
    ]))
    error_message = "Every table cluster_key must reference a key in databricks_clusters."
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_clusters" {
  description = "Clusters keyed by cluster name, each with an independent policy. library_paths contribute to complete metastore-scoped artifact allowlists; use plan-known configured names for artifact paths, not resource IDs."
  type = map(object({
    policy = object({
      group                   = string
      group_permission        = optional(string, "CAN_USE")
      max_clusters_per_user   = optional(number, 3)
      dbus_per_hour           = optional(number, 5)
      autotermination_minutes = optional(number, 10)
      data_security_mode      = optional(string, "USER_ISOLATION")
    })

    num_workers_min     = optional(number, 1)
    num_workers_max     = optional(number, 1)
    spark_env_variable  = optional(map(string), {})
    spark_conf_variable = optional(map(string), {})

    library_paths = optional(map(object({
      artifact      = string
      artifact_type = string
      match_type    = string
    })), {})
    jar_libraries = optional(map(string), {})
    whl_libraries = optional(map(string), {})

    azure_attributes = optional(object({
      attributes = object({
        availability       = string
        first_on_demand    = number
        spot_bid_max_price = number
      })
    }))

    aws_attributes = optional(object({
      attributes = object({
        availability           = string
        zone_id                = string
        first_on_demand        = number
        spot_bid_price_percent = number
        instance_profile_arn   = string
      })
    }))
  }))
  default  = {}
  nullable = false

  validation {
    condition = try(alltrue(flatten([
      for cluster in values(var.databricks_clusters) : [
        for matcher in values(cluster.library_paths) :
        contains(["INIT_SCRIPT", "LIBRARY_JAR", "LIBRARY_MAVEN"], matcher.artifact_type)
      ]
    ])), false)
    error_message = "Cluster library_paths artifact_type must be INIT_SCRIPT, LIBRARY_JAR, or LIBRARY_MAVEN."
  }

  validation {
    condition = try(alltrue(flatten([
      for cluster in values(var.databricks_clusters) : [
        for matcher in values(cluster.library_paths) : matcher.match_type == "PREFIX_MATCH"
      ]
    ])), false)
    error_message = "Cluster library_paths match_type must be PREFIX_MATCH."
  }

  validation {
    condition = try(alltrue(flatten([
      for cluster in values(var.databricks_clusters) : [
        for matcher in values(cluster.library_paths) : trimspace(matcher.artifact) != ""
      ]
    ])), false)
    error_message = "Cluster library_paths artifact must be non-null and nonblank."
  }
}

variable "manage_artifact_allowlists" {
  description = "Whether this root owns complete metastore-scoped allowlists for the configured artifact types. When false, an external owner must provide all required matchers and ensure readiness before clusters are applied. Changing this flag does not automatically migrate ownership or existing state."
  type        = bool
  default     = true
  nullable    = false
}

variable "databricks_artifact_allowlists" {
  description = "Additional matchers keyed by artifact type, merged with cluster library_paths into the complete metastore-scoped allowlist for each type, including all consumers. Use plan-known configured names for artifact paths, not resource IDs. No cross-root coordination or automatic ownership migration is performed."
  type = map(set(object({
    artifact   = string
    match_type = string
  })))
  default  = {}
  nullable = false

  validation {
    condition = alltrue([
      for artifact_type in keys(var.databricks_artifact_allowlists) :
      contains(["INIT_SCRIPT", "LIBRARY_JAR", "LIBRARY_MAVEN"], artifact_type)
    ])
    error_message = "Additional artifact allowlist keys must be INIT_SCRIPT, LIBRARY_JAR, or LIBRARY_MAVEN."
  }

  validation {
    condition = alltrue([
      for matchers in values(var.databricks_artifact_allowlists) : try(length(matchers) > 0, false)
    ])
    error_message = "Each additional artifact allowlist must contain a nonempty, non-null matcher set."
  }

  validation {
    condition = try(alltrue(flatten([
      for matchers in values(var.databricks_artifact_allowlists) : [
        for matcher in matchers : matcher.match_type == "PREFIX_MATCH"
      ]
    ])), false)
    error_message = "Additional artifact allowlist match_type must be PREFIX_MATCH."
  }

  validation {
    condition = try(alltrue(flatten([
      for matchers in values(var.databricks_artifact_allowlists) : [
        for matcher in matchers : trimspace(matcher.artifact) != ""
      ]
    ])), false)
    error_message = "Additional artifact allowlist artifact must be non-null and nonblank."
  }
}

variable "databricks_sql_warehouses" {
  description = "SQL warehouses keyed by warehouse name."

  type = map(object({
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
  }))

  default  = {}
  nullable = false
}

variable "databricks_workspace_groups" {
  description = "Groups, memberships, workspace entitlements, and account-group workspace assignments."

  type = map(object({
    account_group = optional(bool, false)
    members       = optional(map(string), {})

    allow_cluster_create        = optional(bool)
    allow_instance_pool_create  = optional(bool)
    allow_databricks_sql_access = optional(bool)

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
    condition = alltrue([
      for group in values(var.databricks_workspace_groups) :
      group.account_group || length(group.workspace_assignments) == 0
    ])
    error_message = "workspace_assignments can only be configured for account groups."
  }

  validation {
    condition = alltrue([
      for group in values(var.databricks_workspace_groups) :
      group.account_group || group.workspace_entitlements == null
    ])
    error_message = "workspace_entitlements can only be configured for account groups; workspace-local groups must use the inline entitlement flags."
  }

  validation {
    condition = alltrue(flatten([
      for group in values(var.databricks_workspace_groups) : [
        for assignment in values(group.workspace_assignments) :
        contains(["USER", "ADMIN"], assignment.permission)
      ]
    ]))
    error_message = "Workspace assignment permission must be USER or ADMIN."
  }
}

variable "databricks_secret_scope" {
  type        = string
  description = "Databricks Secret Scope Name"
  default     = "example_secret_scope"
}

variable "databricks_secrets" {
  description = "Map of Databricks Secrets"
  default     = []
  sensitive   = true
  type = list(object({
    secret_name  = string
    secret_value = string
  }))
}

variable "databricks_instance_pools" {
  description = "Driver and worker-node instance pool configurations."
  type = map(object({
    name         = string
    max_capacity = number
  }))
  nullable = false

  default = {
    driver = {
      name         = "example-driver-instace-pool"
      max_capacity = 2
    }
    node = {
      name         = "example-node-instace-pool"
      max_capacity = 2
    }
  }

  validation {
    condition = (
      length(var.databricks_instance_pools) == 2 &&
      contains(keys(var.databricks_instance_pools), "driver") &&
      contains(keys(var.databricks_instance_pools), "node") &&
      alltrue([
        for pool in values(var.databricks_instance_pools) : pool != null
      ])
    )
    error_message = "Provide exactly two non-null instance pool configurations: driver and node."
  }
}

variable "tags" {
  type        = map(string)
  description = "Azure Resource Tag(s)"
  default     = {}
}

variable "client_secret_expiration" {
  type        = string
  description = "Service Account Secret Relative Expiration from Creation"
  default     = "1h"
}
