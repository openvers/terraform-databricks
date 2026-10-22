terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

locals {
  program = "data-transformation"
  project = "databricks-etl"
}

locals {
  tags = merge(var.tags, {
    program = local.program
    project = local.project
    env     = "dev"
  })
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS EXTERNAL LOCATION RESOURCE
##
## This resource block creates a Databricks external location.
##
## Parameters:
## - `name`: The name of the Databricks external location.
## - `url`: The URL of the external storage.
## - `credential_name`: The name of the Databricks storage credential.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_external_location" "this" {
  provider        = databricks.workspace
  name            = var.databricks_external_location_name
  url             = "${var.databricks_external_storage_url}/databricks_external"
  credential_name = var.databricks_storage_credential_id

  force_destroy   = true
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CATALOG RESOURCE
##
## This resource block creates a Databricks catalog.
##
## Parameters:
## - `storage_root`: The URL of the external storage.
## - `name`: The name of the Databricks catalog.
## - `comment`: A comment or description for the catalog.
## - `properties`: A map of tags to associate with the catalog.
## - `force_destroy`: A flag to enable force destroy when catalog in not empty.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_catalog" "this" {
  provider     = databricks.workspace
  depends_on   = [ databricks_external_location.this ]

  storage_root = "${var.databricks_external_storage_url}/databricks_external"
  name         = var.databricks_catalog_name
  comment      = var.databricks_catalog_comment
  properties = local.tags

  force_destroy = true
}


## ---------------------------------------------------------------------------------------------------------------------
## TIME SLEEP RESOURCE
##
## This resource defines a delay to allow time for Databricks Metastore assignment to propagate to Workspace.
##
## Parameters:
## - `create_duration`: The duration for the time sleep.
## ---------------------------------------------------------------------------------------------------------------------
resource "time_sleep" "metastore_assignment_propogation" {
  depends_on = [ 
    databricks_catalog.this,
  ]

  create_duration = "20s"
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GRANTS RESOURCE
##
## This resource block manages grants on a Databricks catalog.
##
## Parameters:
## - `catalog`: The name of the Databricks catalog to apply the grants to.
## - `principal`: The principal (user or group) to grant privileges to.
## - `privileges`: A list of privileges to grant to the principal.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_grants" "this" {
  provider   = databricks.workspace
  depends_on = [ 
    databricks_catalog.this,
    time_sleep.metastore_assignment_propogation,
  ]

  catalog  = databricks_catalog.this.name

  dynamic "grant" {
    for_each = var.databricks_catalog_grants
    
    content {
      principal = grant.value.principal
      privileges = grant.value.privileges
    }

  }
}