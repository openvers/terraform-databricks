## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "git_url" {
  type        = string
  description = "Databricks Assets/Task Git Repo URL"
}

variable "git_username" {
  type        = string
  description = "Git Provider User Name"
}

variable "git_pat" {
  type        = string
  description = "Git Personal Access Token"
}

## ---------------------------------------------------------------------------------------------------------------------
## OPTIONAL PARAMETERS
## These variables have defaults and may be overridden
## ---------------------------------------------------------------------------------------------------------------------

variable "git_provider" {
  type        = string
  description = "Databricks Assets/Tasks Git Source Provider"
  default     = "gitHub"
}

variable "git_branch" {
  type        = string
  description = "Git Repo Branch Name"
  default     = "main"
}