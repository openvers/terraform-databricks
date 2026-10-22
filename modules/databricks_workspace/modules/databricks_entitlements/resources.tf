terraform {
  required_version = ">= 1.3.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
  }
}


resource "databricks_entitlements" "this" {
  provider = databricks.workspace

  group_id                   = var.group_id
  workspace_access           = var.workspace_access
  databricks_sql_access      = var.databricks_sql_access
  allow_cluster_create       = var.allow_cluster_create
  allow_instance_pool_create = var.allow_instance_pool_create
}
