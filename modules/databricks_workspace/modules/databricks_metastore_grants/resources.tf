terraform {
  required_version = ">= 1.2.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## AUTHORITATIVE METASTORE GRANTS
## An empty grants list still manages the metastore and revokes existing grants.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_grants" "this" {
  provider  = databricks.workspace
  metastore = var.metastore_id

  dynamic "grant" {
    for_each = var.grants

    content {
      principal  = grant.value.principal
      privileges = grant.value.privileges
    }
  }
}
