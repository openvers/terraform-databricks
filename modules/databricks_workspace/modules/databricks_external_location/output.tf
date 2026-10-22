output "databricks_external_location_id" {
  description = "ID of the managed external location."
  value       = databricks_external_location.this.id
}

output "databricks_external_location_name" {
  description = "Name of the managed external location."
  value       = databricks_external_location.this.name
}

output "databricks_external_location_url" {
  description = "URL of the managed external location."
  value       = databricks_external_location.this.url
}

output "databricks_catalog_id" {
  description = "ID of the managed catalog, or null when catalog registration is disabled."
  value       = var.catalog == null ? null : databricks_catalog.this["this"].id
}

output "databricks_catalog_name" {
  description = "Name of the managed catalog, or null when catalog registration is disabled."
  value       = var.catalog == null ? null : databricks_catalog.this["this"].name
}
