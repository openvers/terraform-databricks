output "metastore_id" {
  description = "Databricks Account Metastore ID"
  value       = databricks_metastore.this.metastore_id
}