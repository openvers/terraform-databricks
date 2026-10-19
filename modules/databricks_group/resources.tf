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
      error_message = "account_group=true cannot enable workspace entitlements. Leave all entitlement flags false or null and manage entitlements separately through the workspace provider."
    }

    precondition {
      condition     = length(var.member_ids) == 0 || length(var.members) == 0
      error_message = "Use either members or member_ids, not both. Migrating existing memberships requires explicit state moves from counted to keyed resource addresses."
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP MEMBER RESOURCE
##
## Adds a member to a Databricks group. The member can be either a user or a service principal.
##
## Parameters:
## - `group_id`: The ID of the Databricks group.
## - `member_id`: The ID of the member to add to the group.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "this" {
  provider = databricks.workspace
  count    = length(var.member_ids)

  group_id  = databricks_group.this.id
  member_id = var.member_ids[count.index]
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS KEYED GROUP MEMBER RESOURCE
##
## Adds Databricks identities to the group using stable logical membership keys and potentially computed member IDs.
## Existing counted memberships remain unchanged unless the caller explicitly migrates their state addresses.
##
## Parameters:
## - `group_id`: Databricks ID of the group created by this module.
## - `member_id`: Databricks SCIM ID of the user, service principal or nested group to add.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "keyed" {
  provider = databricks.workspace
  for_each = var.members

  group_id  = databricks_group.this.id
  member_id = each.value
}
