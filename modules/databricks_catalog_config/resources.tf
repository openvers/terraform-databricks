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
  # Partition ownership before flattening or resolving cluster IDs.
  storage_catalogs = {
    for catalog_key, catalog in var.databricks_catalog_config :
    catalog_key => catalog
    if var.phase == "storage"
  }

  table_catalogs = {
    for catalog_key, catalog in var.databricks_catalog_config :
    catalog_key => catalog
    if var.phase == "tables"
  }

  storage_schemas = {
    for schema in flatten([
      for catalog_key, catalog in local.storage_catalogs : [
        for schema_name, schema in catalog.schemas : {
          key          = jsonencode([catalog_key, schema_name])
          catalog_key  = catalog_key
          catalog_name = catalog.name
          schema_name  = schema_name
          force_delete = schema.force_delete
          comment      = schema.comment
          properties   = schema.properties
          volumes      = schema.volumes
        }
      ]
    ]) : schema.key => schema
  }

  storage_volumes = {
    for volume in flatten([
      for schema_key, schema in local.storage_schemas : [
        for volume_name, volume in schema.volumes : {
          key = jsonencode([
            schema.catalog_key,
            schema.schema_name,
            volume_name,
          ])
          catalog_key      = schema.catalog_key
          catalog_name     = schema.catalog_name
          schema_name      = schema.schema_name
          volume_name      = volume_name
          volume_type      = volume.volume_type
          storage_location = volume.storage_location
          storage_path     = volume.storage_path
          comment          = volume.comment
        }
      ]
    ]) : volume.key => volume
  }

  # Keep a list to preserve volume-name/file-name ordering within each schema.
  storage_file_entries = flatten([
    for schema_key, schema in local.storage_schemas : [
      for volume_name, volume in schema.volumes : [
        for file_name, content_base64 in volume.files : {
          key = jsonencode([
            schema.catalog_key,
            schema.schema_name,
            volume_name,
            file_name,
          ])
          schema_key     = schema_key
          catalog_name   = schema.catalog_name
          schema_name    = schema.schema_name
          volume_name    = volume_name
          file_name      = file_name
          content_base64 = content_base64
        }
      ]
    ]
  ])

  storage_files = {
    for file in local.storage_file_entries :
    file.key => file
  }

  table_schemas = {
    for schema in flatten([
      for catalog_key, catalog in local.table_catalogs : [
        for schema_name, schema in catalog.schemas : {
          key          = jsonencode([catalog_key, schema_name])
          catalog_key  = catalog_key
          catalog_name = catalog.name
          schema_name  = schema_name
          tables       = schema.tables
        }
        if length(schema.tables) > 0
      ]
    ]) : schema.key => schema
  }

  # No cluster-ID lookup occurs here or anywhere in storage expansion.
  table_entries = flatten([
    for schema_key, schema in local.table_schemas : [
      for table_name, table in schema.tables : {
        key = jsonencode([
          schema.catalog_key,
          schema.schema_name,
          table_name,
        ])
        schema_key         = schema_key
        catalog_name       = schema.catalog_name
        schema_name        = schema.schema_name
        table_name         = table_name
        cluster_key        = table.cluster_key
        table_type         = table.table_type
        data_source_format = table.data_source_format
        storage_location   = table.storage_location
        comment            = table.comment
        table_columns      = table.table_columns
      }
    ]
  ])

  tables = {
    for table in local.table_entries :
    table.key => table
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CATALOG RESOURCE
##
## This resource defines a Databricks UC Catalog.
##
## Parameters:
## - `catalog_name`: Databricks Unity Catalog name.
## - `name`: Databricks Unity Catalog Schema name.
## - `comment`: Commentary to add to Unity Catalog Schema.
## - `properties`: Mapping of Unity Catalog Schema properties.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_catalog" "this" {
  provider = databricks.workspace
  for_each = {
    for catalog_key, catalog in local.storage_catalogs :
    catalog_key => catalog
    if catalog.create
  }

  name          = each.value.name
  comment       = each.value.comment
  properties    = each.value.properties
  force_destroy = each.value.force_delete
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SCHEMA RESOURCE
##
## This resource defines a Databricks Unity Catalog Schema.
##
## Parameters:
## - `catalog_name`: Databricks Unity Catalog name.
## - `name`: Databricks Unity Catalog Schema name.
## - `comment`: Commentary to add to Unity Catalog Schema.
## - `properties`: Mapping of Unity Catalog Schema properties.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_schema" "this" {
  provider = databricks.workspace
  for_each = local.storage_schemas

  depends_on = [databricks_catalog.this]

  catalog_name  = each.value.catalog_name
  name          = each.value.schema_name
  comment       = each.value.comment
  properties    = each.value.properties
  force_destroy = each.value.force_delete
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS VOLUME RESOURCE
##
## This resource defines a Databricks Unity Catalog Volume.
##
## Parameters:
## - `catalog_name`: Databricks Unity Catalog name.
## - `schema_name`: Databricks Unity Catalog Schema name.
## - `name`: Databricks Unity Catalog Volume name.
## - `volume_type`: Unity Catalog Volume type.
## - `comment`: Commentary to add to Unity Catalog Schema.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_volume" "this" {
  provider = databricks.workspace
  for_each = local.storage_volumes

  depends_on = [databricks_schema.this]

  catalog_name = each.value.catalog_name
  schema_name  = each.value.schema_name
  name         = each.value.volume_name
  volume_type  = each.value.volume_type
  comment      = each.value.comment

  storage_location = each.value.volume_type == "MANAGED" ? null : (
    each.value.storage_path != null
    ? each.value.storage_path
    : "${each.value.storage_location}/volumes/${each.value.volume_name}"
  )
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS FILE RESOURCE
##
## This resource defines a Databricks Unity Catalog File.
##
## Parameters:
## - `path`: Databricks Unity Catalog File path.
## - `content_base64`: Base64 encoded content for file upload.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_file" "this" {
  provider = databricks.workspace
  for_each = local.storage_files

  depends_on = [databricks_volume.this]

  path = "/Volumes/${each.value.catalog_name}/${each.value.schema_name}/${each.value.volume_name}/${each.value.file_name}"

  content_base64 = each.value.content_base64
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SQL TABLE RESOURCE
##
## This resource defines a Databricks Unity Catalog SQL Table.
##
## Parameters:
## - `cluster_id`: Optional Databricks cluster ID to execute SQL commands with.
## - `cataalog_name`: Name of existing catalog to store the table in.
## - `schema_name`: Name of existing schema to store the table in.
## - `name`: Name of the SQL table.
## - `table_type`: Distinguishes a view vs. managed/external table.
## - `data_source_format`: Table file format.
## - `storage_location`: Table file URL storage location.
## - `comment`: Description of table contents.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_sql_table" "this" {
  provider = databricks.workspace
  for_each = local.tables

  # Catalog/schema readiness is supplied by the caller.
  # This phase intentionally creates no catalog or schema resources.
  cluster_id         = var.cluster_ids[each.value.cluster_key]
  catalog_name       = each.value.catalog_name
  schema_name        = each.value.schema_name
  name               = each.value.table_name
  table_type         = each.value.table_type
  data_source_format = each.value.data_source_format
  storage_location   = "${each.value.storage_location}/tables/${each.value.table_name}"
  comment            = each.value.comment

  dynamic "column" {
    for_each = {
      for column in each.value.table_columns :
      column.name => column
    }

    content {
      name     = column.value.name
      type     = column.value.type
      comment  = column.value.comment
      nullable = column.value.nullable
    }
  }
}
