output "databricks_schema_table_paths" {
  description = "Table paths keyed by JSON-encoded catalog/schema tuples for schemas containing tables."
  value = {
    for schema_key, tables in module.databricks_catalog_tables :
    schema_key => tables.databricks_schema_table_paths
  }
}
