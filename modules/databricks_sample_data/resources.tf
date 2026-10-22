terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
    http = {
      source = "hashicorp/http"
    }
  }
}

locals {
  datasets = {
    holdings = {
      file_name = "example_holdings.csv"
      url       = "https://duckdb.org/data/holdings.csv"
    }
    weather = {
      file_name = "example_weather.csv"
      url       = "https://duckdb.org/data/weather.csv"
    }
  }

  sample_catalogs = {
    for catalog_key, catalog in var.databricks_catalog_config :
    catalog_key => catalog
    if catalog.sample_data.enabled
  }

  sample_files = {
    for file in flatten([
      for catalog_key, catalog in local.sample_catalogs : [
        for dataset_key, dataset in local.datasets : {
          catalog_key = catalog_key
          dataset_key = dataset_key
          file_name   = dataset.file_name
        }
      ]
    ]) :
    jsonencode([file.catalog_key, file.dataset_key]) => file
  }
}

resource "databricks_schema" "this" {
  provider = databricks.workspace
  for_each = local.sample_catalogs

  catalog_name = each.value.name
  name         = "terraform_samples"
}

# Managed storage is inherited from the parent catalog through the schema.
resource "databricks_volume" "this" {
  provider = databricks.workspace
  for_each = local.sample_catalogs

  catalog_name = databricks_schema.this[each.key].catalog_name
  schema_name  = databricks_schema.this[each.key].name
  name         = "datasets"
  volume_type  = "MANAGED"
}

data "http" "this" {
  for_each = length(local.sample_catalogs) > 0 ? local.datasets : {}

  url = each.value.url

  request_headers = {
    Accept = "text/csv"
  }
}

resource "databricks_file" "this" {
  provider = databricks.workspace
  for_each = local.sample_files

  path = "${databricks_volume.this[each.value.catalog_key].volume_path}/${each.value.file_name}"

  content_base64 = data.http.this[
    each.value.dataset_key
  ].response_body_base64
}
