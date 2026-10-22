## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "cluster_policy_name" {
  type        = string
  description = "Databricks Cluster Policy Name"
}

variable "group_name" {
  type        = string
  description = "Databricks Group/Team Name"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "group_permission" {
  type        = string
  description = "Databricks Group/Team Cluster Access Control Permission"
  default     = "CAN_USE"
}

variable "max_clusters_per_user" {
  type        = number
  description = "Max allowabled Clusters a user can use at a single time"
  default     = 3
}

variable "dbus_per_hour" {
  type        = number
  description = "Policy Maximum DBUs Per Hour"
  default     = 5
}

variable "instance_pool_autotermination" {
  type        = number
  description = "Databricks Instance Pool's Maximum Idle Time Before Termination (in Minutes)"
  default     = 10
}

variable "data_security_mode" {
  type        = string
  description = "Databricks Unity Catalog Feature to secure access/isolation. (Default: NONE)"
  default     = "NONE"
}

variable "policy_overrides" {
  type        = map
  description = "Cluser Policy Overrides"
  default     = {}
}