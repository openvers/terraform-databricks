terraform {
  required_version = ">= 1.9"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
  }
}

locals {
  # Tuple keys keep repeated schema names in different catalogs independent.
  databricks_catalog_schemas = {
    for schema in flatten([
      for catalog_name, catalog in var.databricks_catalog_config : [
        for schema_name, schema in catalog.schemas : {
          catalog_name = catalog_name
          schema_name  = schema_name
          tables       = schema.tables
        }
      ]
    ]) : jsonencode([schema.catalog_name, schema.schema_name]) => schema
  }
}

module "databricks_catalog_tables" {
  source = "../.."
  # The child keys tables by name, so isolate each catalog/schema pair.
  for_each = {
    for schema_key, schema in local.databricks_catalog_schemas : schema_key => schema
    if length(schema.tables) > 0
  }

  # The caller supplies catalog/storage and cluster readiness via depends_on.
  databricks_tables = [
    for table_name, table in each.value.tables : {
      cluster_id         = var.cluster_ids[table.cluster_key]
      catalog_name       = each.value.catalog_name
      schema_name        = each.value.schema_name
      table_name         = table_name
      table_type         = table.table_type
      data_source_format = table.data_source_format
      storage_location   = table.storage_location
      comment            = table.comment
      table_columns      = table.table_columns
    }
  ]

  providers = {
    databricks.workspace = databricks.workspace
  }
}
