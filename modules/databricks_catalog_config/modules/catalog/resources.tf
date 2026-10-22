terraform {
  required_version = ">= 1.3"

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
      for catalog_key, catalog in var.databricks_catalog_config : [
        for schema_name, schema in catalog.schemas : {
          catalog_key  = catalog_key
          catalog_name = catalog.name
          schema_name  = schema_name
          comment      = schema.comment
          properties   = schema.properties
          volumes      = schema.volumes
        }
      ]
    ]) : jsonencode([schema.catalog_key, schema.schema_name]) => schema
  }
}

module "databricks_catalogs" {
  source   = "../.."
  for_each = var.databricks_catalog_config

  databricks_catalogs = each.value.create ? [{
  key        = each.key
  name       = each.value.name
  comment    = each.value.comment
  properties = each.value.properties
}] : []

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_catalog_storage" {
  source   = "../.."
  for_each = local.databricks_catalog_schemas

  depends_on = [module.databricks_catalogs]

  databricks_schemas = [{
    catalog_name = each.value.catalog_name
    schema_name  = each.value.schema_name
    comment      = each.value.comment
    properties   = each.value.properties
  }]

  databricks_volumes = [
    for volume_name, volume in each.value.volumes : {
      catalog_name     = each.value.catalog_name
      schema_name      = each.value.schema_name
      volume_name      = volume_name
      volume_type      = volume.volume_type
      storage_location = volume.storage_location
      storage_path     = volume.storage_path
      comment          = volume.comment
    }
  ]

  # The flat child uses list indexes for files, so identical names in separate volumes are safe.
  databricks_files = flatten([
    for volume_name, volume in each.value.volumes : [
      for file_name, content_base64 in volume.files : {
        catalog_name   = each.value.catalog_name
        schema_name    = each.value.schema_name
        volume_name    = volume_name
        file_name      = file_name
        content_base64 = content_base64
      }
    ]
  ])

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_sample_data" {
  source = "../../../databricks_sample_data"
  for_each = {
    for catalog_name, catalog in var.databricks_catalog_config : catalog_name => catalog
    if catalog.sample_data.enabled
  }

  depends_on = [module.databricks_catalogs]

  catalog_name = each.value.name

  providers = {
    databricks.workspace = databricks.workspace
  }
}
