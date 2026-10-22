output "databricks_external_location_url" {
  description = "Databricks Metastore External Location URL"
  value       = databricks_external_location.this.url
}

output "databricks_catalog_name" {
  description = "Databricks Metastore Catalog Name"
  value       = databricks_catalog.this.id
}