terraform {
  required_version = ">= 1.2.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.accounts]
    }
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS METASTORE RESOURCE
##
## Creates an account-scoped metastore independently of any workspace.
## Assignment, propagation delays and workspace grants are intentionally no longer
## managed here; their former inputs and the workspace provider alias are removed.
## A null owner leaves ownership selection to the backend, not necessarily the caller.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_metastore" "this" {
  provider      = databricks.accounts
  name          = var.databricks_metastore_name
  owner         = var.databricks_unity_admin_group
  region        = var.cloud_region
  storage_root  = var.databricks_storage_root
  force_destroy = var.force_destroy
}
