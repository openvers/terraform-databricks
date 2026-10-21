terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SECRET SCOPE RESOURCE
##
## This resource creates a secret scope in Databricks.
## 
## Parameters:
## - `name`: The name of the secret scope. Example: "my_secret_scope"
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_secret_scope" "this" {
  provider = databricks.workspace
  
  name     = var.secret_scope
}
