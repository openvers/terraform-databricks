output "databricks_volume_storage_paths" {
  description = "Configured external backing storage URIs keyed by JSON-encoded [logical catalog key, logical schema key, volume name]. Respects exact storage_path overrides; managed volumes have null entries, not their physical storage locations."
  value       = local.volume_storage_paths
}

output "databricks_volume_file_paths" {
  description = "Uploaded file IDs grouped by JSON-encoded [logical catalog key, logical schema key]."

  value = {
    for schema_resource_key, schema in local.storage_schemas :
    schema_resource_key => [
      for file in local.storage_file_entries :
      databricks_file.this[file.key].id
      if file.schema_resource_key == schema_resource_key
    ]
  }
}

output "databricks_schema_table_paths" {
  description = "Table IDs grouped by JSON-encoded [logical catalog key, logical schema key]."

  value = {
    for schema_resource_key, schema in local.table_schemas :
    schema_resource_key => [
      for table in local.table_entries :
      databricks_sql_table.this[table.key].id
      if table.schema_resource_key == schema_resource_key
    ]
  }
}
