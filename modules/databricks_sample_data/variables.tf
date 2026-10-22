variable "databricks_catalog_config" {
  description = "Catalogs eligible for sample provisioning, keyed by logical catalog identity."
  type = map(object({
    name = string
    sample_data = optional(object({
      enabled = optional(bool, false)
    }), {})
  }))
  default  = {}
  nullable = false
}