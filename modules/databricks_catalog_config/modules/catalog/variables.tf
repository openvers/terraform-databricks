variable "databricks_catalog_config" {
  description = "Unity Catalog storage configuration keyed by catalog, schema, volume, and file names. File values are base64-encoded content."
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
}
