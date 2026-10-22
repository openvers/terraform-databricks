terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS TOKEN RESOURCE
##
## This resource creates a token in Databricks.
## 
## Parameters:
## - `comment`: A comment to describe the purpose of the token. Example: "Databricks CLI Provisioning"
## - `lifetime_seconds`: The lifetime of the token in seconds. Example: 86400 (1 day)
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_token" "this" {
  provider          = databricks.workspace

  comment           = var.databricks_token_comment
  lifetime_seconds  = var.databricks_token_lifetime
}
