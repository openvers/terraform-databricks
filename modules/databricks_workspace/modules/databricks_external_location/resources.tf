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
  catalogs = var.catalog == null ? {} : { this = var.catalog }
}

resource "databricks_external_location" "this" {
  provider = databricks.workspace

  name            = var.external_location_name
  url             = var.external_location_url
  credential_name = var.storage_credential_name
  read_only       = var.read_only
  force_destroy   = var.force_destroy
}

# Always authoritative, including when no grant blocks are configured.
resource "databricks_grants" "external_location" {
  provider = databricks.workspace

  external_location = databricks_external_location.this.id

  dynamic "grant" {
    for_each = var.external_location_grants

    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}

resource "databricks_catalog" "this" {
  provider = databricks.workspace
  for_each = local.catalogs

  # storage_root is independent input; explicitly wait for location/grant readiness.
  depends_on = [databricks_grants.external_location]

  name          = each.value.name
  storage_root  = each.value.storage_root
  comment       = each.value.comment
  force_destroy = each.value.force_destroy
}

# Keep this label scoped to catalog grants, as in the previous implementation.
resource "databricks_grants" "this" {
  provider = databricks.workspace
  for_each = var.manage_catalog_grants ? local.catalogs : {}

  catalog = databricks_catalog.this[each.key].name

  dynamic "grant" {
    for_each = var.catalog_grants

    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
