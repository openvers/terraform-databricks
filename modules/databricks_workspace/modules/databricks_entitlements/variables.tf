## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "group_id" {
  type        = number
  description = "Databricks Group/Team ID"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "workspace_access" {
  description = "Group Permission to Workspace Access"
  type        = bool
  default     = false
}

variable "databricks_sql_access" {
  description = "Group Permission to Workspace SQL Warehouse Access"
  type        = bool
  default     = false
}

variable "allow_cluster_create" {
  description = "Group Permission to Workspace Cluster Creation"
  type        = bool
  default     = false
}

variable "allow_instance_pool_create" {
  description = "Group Permission to Workspace Cluster Pool Configuration"
  type        = bool
  default     = false
}
