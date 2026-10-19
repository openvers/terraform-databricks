## ---------------------------------------------------------------------------------------------------------------------
## MODULE PARAMETERS
## These variables are expected to be passed in by the operator
## ---------------------------------------------------------------------------------------------------------------------

variable "display_name" {
  type        = string
  description = "Display name for the Databricks-managed account service principal. Existing identities must be explicitly imported; the module does not implicitly adopt them."
  nullable    = false

  validation {
    condition = (
      length(trimspace(var.display_name)) > 0 &&
      var.display_name == trimspace(var.display_name) &&
      length(regexall("[\t\r\n]", var.display_name)) == 0
    )
    error_message = "display_name must be nonempty, without surrounding whitespace or tab/newline characters."
  }
}
