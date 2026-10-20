## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "cloud_region" {
  type        = string
  description = "Cloud region in which to create the account metastore."
  nullable    = false

  validation {
    condition     = trimspace(var.cloud_region) != "" && var.cloud_region == trimspace(var.cloud_region)
    error_message = "cloud_region must be nonblank and have no leading or trailing whitespace."
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_metastore_name" {
  type        = string
  description = "Display Name for Databricks Accounts Metastore"
  default     = "Primary"
  nullable    = false

  validation {
    condition     = trimspace(var.databricks_metastore_name) != "" && var.databricks_metastore_name == trimspace(var.databricks_metastore_name)
    error_message = "databricks_metastore_name must be nonblank and have no leading or trailing whitespace."
  }
}

variable "databricks_unity_admin_group" {
  type        = string
  description = "Optional preexisting account principal (username, group name or service-principal application ID) to own the metastore. Null leaves ownership selection to the backend, not necessarily the caller; no principal or account-admin grant is created."
  default     = null
  nullable    = true

  validation {
    condition     = var.databricks_unity_admin_group == null ? true : trimspace(var.databricks_unity_admin_group) != "" && var.databricks_unity_admin_group == trimspace(var.databricks_unity_admin_group)
    error_message = "databricks_unity_admin_group must be null or nonblank with no leading or trailing whitespace."
  }
}

variable "databricks_storage_root" {
  type        = string
  description = "Optional root storage path for the metastore. Null omits the storage root."
  default     = null
  nullable    = true

  validation {
    condition     = var.databricks_storage_root == null ? true : trimspace(var.databricks_storage_root) != "" && var.databricks_storage_root == trimspace(var.databricks_storage_root)
    error_message = "databricks_storage_root must be null or nonblank with no leading or trailing whitespace."
  }
}

variable "force_destroy" {
  type        = bool
  description = "Allow deletion of a nonempty metastore. Enable only after explicitly reviewing the destructive consequences."
  default     = false
  nullable    = false
}
