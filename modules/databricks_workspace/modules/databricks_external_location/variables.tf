## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_storage_credential_id" {
  type        = string
  description = "Databricks Storage Credential"
}

variable "databricks_external_storage_url" {
  type        = string
  description = <<EOT
    Databricks External Storage Location URL. Example:
    s3://example-container/databricks-external-data
  EOT
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_external_location_name" {
  type        = string
  description = "Databricks Workspace Unity Catalog External Location Name"
  default     = "external"
}

variable "databricks_catalog_name" {
  type        = string
  description = "Databricks Unity Catalog Name"
  default     = "sandbox"
}

variable "databricks_catalog_comment" {
  type        = string
  description = "Databricks Unity Catalog Comment"
  default     = "This Catalog is Managed by Terraform"
}

variable "databricks_catalog_grants" {
  description = "List of Databricks Unity Catalog Grant Mappings"
  type        = list(object({
    principal = string
    privileges = list(string)
  }))
  default = [
    {
      principal  = "Data Scientists"
      privileges = ["USE_CATALOG", "CREATE"]
    },
    {
      principal  = "Data Engineers"
      privileges = ["USE_CATALOG"]
    }
  ]
}

variable "tags" {
  description = "Databricks Resource Tag(s)"
  default     = {}
}