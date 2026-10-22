terraform {
  required_version = ">= 1.3.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.accounts]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP RESOURCE DEFINITION
##
## Creates an account group. Workspace assignments and entitlements are managed separately.
## 
## Parameters:
## - `display_name`: Display name of the group. Example: "engineer_group"
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group" "this" {
  provider = databricks.accounts

  display_name = var.group_name
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
  provider = databricks.accounts
  for_each = var.members

  group_id  = databricks_group.this.id
  member_id = each.value
}
