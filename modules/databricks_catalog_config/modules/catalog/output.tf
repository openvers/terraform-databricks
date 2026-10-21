output "databricks_volume_file_paths" {
  description = "Unity Catalog volume file IDs keyed by JSON-encoded [catalog, schema] tuples."
  value = {
    for schema_key, storage in module.databricks_catalog_storage :
    schema_key => storage.databricks_volume_file_paths
  }
}

output "sample_data_file_paths" {
  description = "Optional sample file paths keyed by catalog name, then dataset identity."
  value = {
    for catalog_name, samples in module.databricks_sample_data :
    catalog_name => samples.file_paths
  }
}
