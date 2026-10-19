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
## DATABRICKS SERVICE PRINCIPAL RESOURCE
##
## Creates a Databricks-managed service principal using the caller's account-level provider.
## No external cloud identity registration, credentials, memberships, roles or workspace assignments are created.
## Removing this resource deactivates the account identity rather than permanently deleting it.
##
## Parameters:
## - `display_name`: Human-readable name of the account service principal.
## - `disable_as_user_deletion`: Deactivates the service principal when Terraform removes the resource.
##
## Providers:
## - `databricks.accounts`: Caller-configured account endpoint and authentication, independent of cloud platform.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_service_principal" "this" {
  provider = databricks.accounts

  display_name             = var.display_name
  disable_as_user_deletion = true
}
