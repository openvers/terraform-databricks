output "databricks_access_token" {
  description = "Databricks Workspace Service Principal Access Token"
  value       = module.databricks_workspace_access_token.databricks_token
  sensitive   = true
}

output "databricks_secret_scope_name" {
  description = "Databricks Workspace Secret Scope Name"
  value       = module.databricks_secret_scope.databricks_secret_scope
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
  description = "Optional sample file paths keyed by catalog name, then dataset identity."
  value       = module.databricks_catalog_config.sample_data_file_paths
}

output "databricks_unity_catalog_table_paths" {
  description = "Unity Catalog table paths keyed by JSON-encoded [catalog, schema] tuples."
  value       = module.databricks_catalog_tables.databricks_schema_table_paths
}
