## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "databricks_token_comment" {
  type        = string
  description = "Databricks Personal Access Token Comment"
  default     = "Terraform Provisioning PAT"
}

variable "databricks_token_lifetime" {
  type        = number
  description = "Databricks Personal Access Token Lifetime in Seconds"
  default     = 86400
}