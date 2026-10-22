output "databricks_volume_file_paths" {
  description = "Uploaded file IDs grouped by JSON-encoded [logical catalog key, schema name]."

  value = {
    for schema_key, schema in local.storage_schemas :
    schema_key => [
      for file in local.storage_file_entries :
      databricks_file.this[file.key].id
      if file.schema_key == schema_key
    ]
  }
}

output "databricks_schema_table_paths" {
  description = "Table IDs grouped by JSON-encoded [logical catalog key, schema name]."

  value = {
    for schema_key, schema in local.table_schemas :
    schema_key => [
      for table in local.table_entries :
      databricks_sql_table.this[table.key].id
      if table.schema_key == schema_key
    ]
  }
}