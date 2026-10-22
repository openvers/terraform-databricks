variable "databricks_catalog_config" {
  description = "Table configuration keyed by catalog, schema, and table names."
  type = map(object({
    name    = string 
    schemas = optional(map(object({
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
    condition = alltrue(flatten([
      for catalog in values(var.databricks_catalog_config) : [
        for schema in values(catalog.schemas) : [
          for table in values(schema.tables) : contains(keys(var.cluster_ids), table.cluster_key)
        ]
      ]
    ]))
    error_message = "Every table cluster_key must reference a key in cluster_ids."
  }
}

variable "cluster_ids" {
  description = "Databricks cluster IDs keyed by the cluster keys used in table configuration."
  type        = map(string)
  default     = {}
  nullable    = false
}
