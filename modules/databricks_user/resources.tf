terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP DATA
##
## This data source retrieves information about a group in Databricks.
## 
## Parameters:
## - `display_name`: The display name of the group to retrieve information for. Example: "admins"
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_group" "this" {
  provider     = databricks.workspace
  display_name = var.group_name
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS USER RESOURCE
##
## This resource manages a user in Databricks.
## 
## Parameters:
## - `user_name`: The username of the user to manage.
## - `display_name`: The display name of the user.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_user" "this" {
  provider                 = databricks.workspace
  user_name                = var.user_name
  display_name             = var.display_name
  force                    = true
  force_delete_home_dir    = true
  force_delete_repos       = true
  disable_as_user_deletion = false
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GROUP MEMBER RESOURCE
##
## This resource manages membership of a user in a Databricks group.
## 
## Parameters:
## - `group_id`: The ID of the Databricks group.
## - `member_id`: The ID of the user to add to the group.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_group_member" "this" {
  provider  = databricks.workspace
  group_id  = data.databricks_group.this.id
  member_id = databricks_user.this.id
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS USER ROLE RESOURCE
##
## This resource applies rolesets to Databricks Workspace Users.
## 
## Parameters:
## - `user_id`: The ID of the Databricks User.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_user_role" "this" {
  provider = databricks.workspace
  user_id  = databricks_user.this.id
  role     = var.user_role
}