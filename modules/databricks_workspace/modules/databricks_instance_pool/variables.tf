## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "instance_pool_name" {
  type        = string
  description = "Databricks Instance Pool Name"
}

variable "instance_pool_max_capacity" {
  type        = number
  description = "Databricks Instance Pool's Maximum Number of Allocated Nodes"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "node_min_memory_gb" {
  type        = number
  description = "Databricks Cluster Node's Minimum Memory Requirement (in GBs)"
  default     = 1
}

variable "node_min_cores" {
  type        = number
  description = "Databricks Cluster Node's Minimum Cores Requirement"
  default     = 1
}

variable "node_category" {
  type        = string
  description = "Databricks Cluster Node's Type"
  default     = "General Purpose"
}

variable "instance_pool_min_idle_instances" {
  type        = number
  description = "Databricks Instance Pool's Minimum Idle Instances Allowed"
  default     = 0
}

variable "instance_pool_autotermination" {
  type        = number
  description = "Databricks Instance Pool's Maximum Idle Time Before Termination (in Minutes)"
  default     = 10
}

variable "aws_attributes" {
  description = "AWS Configurations Block within Instance Pool Resource"
  default     = {}
}

variable "azure_attributes" {
  description = "Azure Configurations Block within Instance Pool Resource"
  default     = {}
}

variable "gcp_attributes" {
  description = "GCP Configurations Block within Instance Pool Resource"
  default     = {}
}