## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "phase" {
  description = "Resources managed by this instance: storage or tables."
  type        = string

  validation {
    condition     = contains(["storage", "tables"], var.phase)
    error_message = "phase must be storage or tables."
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_catalog_config" {
  description = "Nested Unity Catalog configuration keyed by logical catalog identity. Catalog and schema force_delete flags independently allow nonempty deletion; false is not deletion protection, and forced parent deletion can remove descendants."
  type = map(object({
    name         = string
    create       = optional(bool, true)
    force_delete = optional(bool, false)
    comment      = optional(string)
    properties   = optional(map(string), {})

    sample_data = optional(object({
      enabled = optional(bool, false)
    }), {})

    schemas = optional(map(object({
      force_delete = optional(bool, false)
      comment      = optional(string)
      properties   = optional(map(string), {})

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
      catalog.sample_data.enabled ? !contains(
        [for name in keys(catalog.schemas) : lower(name)],
        "terraform_samples"
      ) : true
    ])
    error_message = "The terraform_samples schema is reserved when sample_data.enabled is true."
  }

  validation {
    condition = alltrue(flatten([
      for catalog in values(var.databricks_catalog_config) : [
        for schema in values(catalog.schemas) : [
          for volume in values(schema.volumes) : (
            volume.volume_type == "MANAGED" ? volume.storage_location == null : (
              volume.volume_type == "EXTERNAL" ? (
                volume.storage_location == null
                ? false
                : trimspace(volume.storage_location) != ""
              ) : false
            )
          )
        ]
      ]
    ]))
    error_message = "Volumes must be MANAGED with no storage_location, or EXTERNAL with a nonblank storage_location."
  }
}

variable "cluster_ids" {
  description = "Actual cluster IDs keyed by configured cluster_key. Supply only to the tables instance."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition = var.phase == "tables" ? alltrue(flatten([
      for catalog in values(var.databricks_catalog_config) : [
        for schema in values(catalog.schemas) : [
          for table in values(schema.tables) :
          contains(keys(var.cluster_ids), table.cluster_key)
        ]
      ]
    ])) : true

    error_message = "Every table cluster_key must reference a key in cluster_ids during the tables phase."
  }
}
