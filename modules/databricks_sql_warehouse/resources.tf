terraform {
  required_version = ">= 1.3"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
  }
}

resource "databricks_sql_endpoint" "this" {
  provider = databricks.workspace

  name                      = var.warehouse_name
  cluster_size              = var.config.cluster_size
  min_num_clusters          = var.config.min_num_clusters
  max_num_clusters          = var.config.max_num_clusters
  auto_stop_mins            = var.config.auto_stop_mins
  enable_photon             = var.config.enable_photon
  enable_serverless_compute = var.config.enable_serverless_compute
  warehouse_type            = var.config.warehouse_type

  dynamic "tags" {
    for_each = length(var.config.tags) > 0 ? [var.config.tags] : []

    content {
      dynamic "custom_tags" {
        for_each = tags.value

        content {
          key   = custom_tags.key
          value = custom_tags.value
        }
      }
    }
  }
}

resource "databricks_permissions" "this" {
  provider = databricks.workspace
  count    = length(var.config.group_permissions) + length(var.config.user_permissions) + length(var.config.service_principal_permissions) > 0 ? 1 : 0

  sql_endpoint_id = databricks_sql_endpoint.this.id

  dynamic "access_control" {
    for_each = var.config.group_permissions

    content {
      group_name       = access_control.key
      permission_level = access_control.value
    }
  }

  dynamic "access_control" {
    for_each = var.config.user_permissions

    content {
      user_name        = access_control.key
      permission_level = access_control.value
    }
  }

  dynamic "access_control" {
    for_each = var.config.service_principal_permissions

    content {
      service_principal_name = access_control.key
      permission_level       = access_control.value
    }
  }
}
