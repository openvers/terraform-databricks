## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "user_name" {
  type        = string
  description = "User Email with GCP Access (Not a Service Account) for Databricks Workspace Account"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "display_name" {
  type        = string
  description = "Display Name for Databricks Workspace User Account"
  default     = "Databricks Workspace Admin Account"
}

variable "group_name" {
  type        = string
  description = "Display Name for Databricks Workspace Group"
  default     = "Admins"
}

variable "user_role" {
  type        = string
  description = "Databricks User Role"
  default     = "account_admin"
}