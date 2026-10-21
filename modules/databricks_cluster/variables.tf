## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "cluster_name" {
  type        = string
  description = "Databricks Cluster Name"
}

variable "node_instance_pool_id" {
  type        = string
  description = "Databricks Node Instace Pool ID"
}

variable "driver_instance_pool_id" {
  type        = string
  description = "Databricks Driver Instace Pool ID"
}

variable "cluster_policy_name" {
  type        = string
  description = "Databricks Cluster Policy Name"
}

variable "cluster_policy_id" {
  type        = string
  description = "Databricks Cluster Policy ID"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "spark_env_variable" {
  type        = map(string)
  description = "Databricks CLuster Spark Environment Variables"
  default     = {}
}

variable "spark_conf_variable" {
  type        = map(string)
  description = "Databricks Cluster Spark Conf Parameters"
  default     = {}
}

variable "num_workers_min" {
  type        = number
  description = "Databricks Cluster Autoscale workers minimum"
  default     = 1
}

variable "num_workers_max" {
  type        = number
  description = "Databricks Cluster Autoscale workers maximum"
  default     = 1
}

variable "library_paths" {
  description = "Map of Databricks Unity Catalog Library Volume to be included in the ALLOWED LIST on Databricks Cluster"
  default     = null
  type        = map(object({
      artifact      = string
      artifact_type = string
      match_type    = string
  }))
}

variable "jar_libraries" {
  description = "Map of JAR files to install on cluster which can be found in Databricks Unity Catalog Library Volume"
  type        = map(string)
  default     = {}
}

variable "whl_libraries" {
  description = "Map of Python WHL files to install on cluster which can be found in Databricks Unity Catalog Library Volume"
  type        = map(string)
  default     = {}
}

variable "azure_attributes" {
  description = "Azure Compute Configurations for Databricks Clusters"
  default     = null
  type        = object({
    attributes = object({
      availability       = string
      first_on_demand    = number
      spot_bid_max_price = number 
    })
  })
}

variable "aws_attributes" {
  description = "AWS Compute Configurations for Databricks Clusters"
  default     = null
  type        = object({
    attributes = object({
      availability           = string
      zone_id                = string
      first_on_demand        = number
      spot_bid_price_percent = number
      instance_profile_arn   = string
    })
  })
}