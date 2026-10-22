output "databricks_access_token" {
  description = "Databricks workspace PAT, or null when token creation is disabled."
  value       = var.create_databricks_access_token ? module.databricks_workspace_access_token[0].databricks_token : null
  sensitive   = true
}

output "databricks_secret_scope_name" {
  description = "Configured Databricks secret scope name, whether managed or externally owned."
  value       = var.manage_secret_scope ? module.databricks_secret_scope[0].databricks_secret_scope : var.databricks_secret_scope
}

output "databricks_cluster_ids" {
  description = "Databricks Workspace Cluster IDs keyed by cluster name."
  value = {
    for name, cluster in module.databricks_cluster :
    name => cluster.databricks_cluster_id
  }
}

output "databricks_sql_warehouse_ids" {
  description = "SQL warehouse IDs keyed by warehouse name."

  value = {
    for name, warehouse in module.databricks_sql_warehouse :
    name => warehouse.warehouse_id
  }
}

output "databricks_unity_catalog_volume_file_paths" {
  description = "Unity Catalog volume file paths keyed by JSON-encoded [catalog, schema] tuples."
  value       = module.databricks_catalog_config.databricks_volume_file_paths
}

output "databricks_sample_data_file_paths" {
  description = "Sample file paths keyed by logical catalog and dataset."

  value = module.databricks_sample_data.file_paths
}

output "databricks_unity_catalog_table_paths" {
  description = "Unity Catalog table paths keyed by JSON-encoded [catalog, schema] tuples."
  value       = module.databricks_catalog_tables.databricks_schema_table_paths
}
