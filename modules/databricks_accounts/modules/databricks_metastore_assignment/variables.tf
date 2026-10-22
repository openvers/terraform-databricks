variable "metastore_id" {
  type        = string
  description = "Existing metastore ID to assign; must be nonblank without leading or trailing whitespace."
  nullable    = false

  validation {
    condition     = trimspace(var.metastore_id) != "" && var.metastore_id == trimspace(var.metastore_id)
    error_message = "metastore_id must be nonblank and have no leading or trailing whitespace."
  }
}

variable "workspace_id" {
  type        = number
  description = "Numeric Databricks workspace ID, not a cloud resource ID; must be a positive signed 64-bit integer."
  nullable    = false

  validation {
    condition     = var.workspace_id > 0 && var.workspace_id <= 9223372036854775807 && floor(var.workspace_id) == var.workspace_id
    error_message = "workspace_id must be an integer from 1 through 9223372036854775807."
  }
}

variable "propagation_delay_seconds" {
  type        = number
  description = "Bounded post-assignment delay in seconds; zero bypasses the delay. This is not a runtime readiness check."
  default     = 10
  nullable    = false

  validation {
    condition     = var.propagation_delay_seconds >= 0 && var.propagation_delay_seconds <= 600 && floor(var.propagation_delay_seconds) == var.propagation_delay_seconds
    error_message = "propagation_delay_seconds must be an integer from 0 through 600."
  }
}
