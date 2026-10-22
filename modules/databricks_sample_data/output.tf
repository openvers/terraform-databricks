output "file_paths" {
  description = "Uploaded sample paths keyed by logical catalog key and dataset key."

  value = {
    for catalog_key, catalog in local.sample_catalogs :
    catalog_key => {
      for dataset_key, dataset in local.datasets :
      dataset_key => databricks_file.this[
        jsonencode([catalog_key, dataset_key])
      ].path
    }
  }
}