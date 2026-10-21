terraform {
  required_version = ">= 1.3.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace, databricks.workspace_target]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP RESOURCE DEFINITION
##
## This resource block defines a group within Databricks.
## The caller's provider selects account or workspace scope. Account-group mode omits workspace-only entitlements;
## it does not change provider endpoints, migrate group ownership or assign the group to a workspace.
## 
## Parameters:
## - `display_name`: Display name of the group. Example: "engineer_group"
## - `allow_cluster_create`: Workspace cluster-creation entitlement; omitted in account-group mode.
## - `allow_instance_pool_create`: Workspace instance-pool creation entitlement; omitted in account-group mode.
## - `databricks_sql_access`: Workspace SQL entitlement; omitted in account-group mode.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group" "this" {
  provider = databricks.workspace

  display_name               = var.group_name
  allow_cluster_create       = var.account_group ? null : var.allow_cluster_create
  allow_instance_pool_create = var.account_group ? null : var.allow_instance_pool_create
  databricks_sql_access      = var.account_group ? null : var.allow_databricks_sql_access

  lifecycle {
    precondition {
      condition = !var.account_group || (
        var.allow_cluster_create != true &&
        var.allow_instance_pool_create != true &&
        var.allow_databricks_sql_access != true
      )
      error_message = "account_group=true cannot enable inline workspace entitlements. Leave all legacy entitlement flags false or null and use workspace_entitlements through the workspace provider."
    }

    precondition {
      condition     = var.account_group || var.workspace_entitlements == null
      error_message = "workspace_entitlements requires account_group=true. Workspace-local groups must use the inline entitlement flags instead."
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP MEMBER RESOURCE
##
## Adds Databricks identities to the group using stable logical membership keys and potentially computed member IDs.
## Existing counted memberships remain unchanged unless the caller explicitly migrates their state addresses.
##
## Parameters:
## - `group_id`: Databricks ID of the group created by this module.
## - `member_id`: Databricks SCIM ID of the user, service principal or nested group to add.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "this" {
  provider = databricks.workspace
  for_each = var.members

  group_id  = databricks_group.this.id
  member_id = each.value
}

resource "databricks_mws_permission_assignment" "this" {
  provider = databricks.workspace
  for_each = var.workspace_assignments

  workspace_id = each.value.workspace_id
  principal_id = tonumber(databricks_group.this.id)
  permissions  = [each.value.permission]

  lifecycle {
    precondition {
      condition     = var.account_group
      error_message = "Workspace assignments require an account-level group."
    }
  }
}

# Resolve the workspace-visible group only after any managed account assignments finish.
# The target workspace may instead have an assignment managed outside this module.
data "databricks_group" "workspace_target" {
  provider = databricks.workspace_target
  count    = var.workspace_entitlements == null ? 0 : 1

  display_name = databricks_group.this.display_name

  depends_on = [databricks_mws_permission_assignment.this]
}

resource "databricks_entitlements" "this" {
  provider = databricks.workspace_target
  count    = var.workspace_entitlements == null ? 0 : 1

  group_id                   = data.databricks_group.workspace_target[count.index].id
  workspace_access           = try(var.workspace_entitlements.workspace_access, false)
  databricks_sql_access      = try(var.workspace_entitlements.databricks_sql_access, false)
  allow_cluster_create       = try(var.workspace_entitlements.allow_cluster_create, false)
  allow_instance_pool_create = try(var.workspace_entitlements.allow_instance_pool_create, false)
}
