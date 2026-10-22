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
## DATABRICKS WORKSPACE PERMISSION ASSIGNMENT RESOURCE
##
## Assigns an existing account user, group or service principal to an existing Databricks workspace.
## USER grants basic workspace access; ADMIN explicitly grants workspace administrative access.
## No identities, compute entitlements, account-admin roles or Unity Catalog grants are created.
## Removing the resource removes this direct assignment, not the identity; other access paths may remain.
##
## Parameters:
## - `workspace_id`: Numeric Databricks workspace ID, not a cloud resource ID.
## - `principal_id`: Numeric Databricks account identity SCIM ID, not a cloud identity ID.
## - `permissions`: A single USER or ADMIN permission, with USER as the module default.
##
## Providers:
## - `databricks.accounts`: Caller-configured account endpoint and authentication, independent of cloud platform.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_mws_permission_assignment" "this" {
  provider = databricks.accounts

  workspace_id = var.workspace_id
  principal_id = tonumber(var.principal_id)
  permissions  = [var.permission]
}
