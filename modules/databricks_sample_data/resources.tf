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
}

resource "databricks_schema" "this" {
  provider = databricks.workspace

  catalog_name = var.catalog_name
  name         = "terraform_samples"
}

# Managed storage is inherited from the parent catalog through the schema.
resource "databricks_volume" "this" {
  provider = databricks.workspace

  catalog_name = databricks_schema.this.catalog_name
  schema_name  = databricks_schema.this.name
  name         = "datasets"
  volume_type  = "MANAGED"
}

data "http" "this" {
  for_each = local.datasets

  url = each.value.url
  request_headers = {
    Accept = "text/csv"
  }
}

resource "databricks_file" "this" {
  provider = databricks.workspace
  for_each = local.datasets

  path           = "${databricks_volume.this.volume_path}/${each.value.file_name}"
  content_base64 = data.http.this[each.key].response_body_base64
}
