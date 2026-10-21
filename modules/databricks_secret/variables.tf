## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "secret_scope_id" {
  type        = string
  description = "Databricks Secret Scope ID"
}

variable "secret_name" {
  type        = string
  description = "Databricks Secret Name"
}

variable "secret_data" {
  type        = string
  description = "Databricks Secret Data"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------