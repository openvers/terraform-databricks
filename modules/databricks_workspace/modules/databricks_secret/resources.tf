terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SECRET RESOURCE
##
## This resource creates a secret in Databricks.
## 
## Parameters:
## - `key`: The name of the secret. Example: "my_secret"
## - `string_value`: The value of the secret. Example: "my_secret_value"
## - `scope`: The ID of the secret scope where the secret will be stored.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_secret" "this" {
  provider     = databricks.workspace

  key          = var.secret_name
  string_value = var.secret_data
  scope        = var.secret_scope_id
}
