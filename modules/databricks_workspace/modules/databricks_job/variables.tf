variable "name" {
  description = "Name of the workspace job."
  type        = string
  nullable    = false

  validation {
    condition     = length(trimspace(var.name)) > 0 && var.name == trimspace(var.name)
    error_message = "name must be nonblank without leading or trailing whitespace."
  }
}

variable "description" {
  description = "Optional description of the job."
  type        = string
  default     = ""
  nullable    = false
}

variable "tags" {
  description = "Caller-supplied job tags; no cloud-specific tags are added."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for key, value in var.tags : length(trimspace(key)) > 0 && value != null])
    error_message = "tags must have nonblank keys and non-null values."
  }
}

variable "tasks" {
  description = "SQL-file tasks keyed by stable task keys (1-64 tasks). Supply existing WORKSPACE files and Pro or serverless warehouse IDs. The 64-task bound permits complete in-module cycle detection. No clusters, files, warehouses or permissions are created."
  type = map(object({
    warehouse_id              = string
    sql_file_path             = string
    depends_on                = optional(set(string), [])
    parameters                = optional(map(string), {})
    timeout_seconds           = optional(number, 0)
    max_retries               = optional(number, 0)
    min_retry_interval_millis = optional(number, 0)
    retry_on_timeout          = optional(bool, false)
  }))
  nullable = false

  validation {
    condition     = length(var.tasks) >= 1 && length(var.tasks) <= 64
    error_message = "tasks must contain between 1 and 64 tasks for bounded, complete cycle detection."
  }

  validation {
    condition     = alltrue([for key in keys(var.tasks) : can(regex("^[A-Za-z0-9_-]{1,100}$", key))])
    error_message = "Task keys must contain 1-100 alphanumeric, underscore or hyphen characters."
  }

  validation {
    condition = alltrue([for key, task in var.tasks : try(
      length(trimspace(task.warehouse_id)) > 0 && task.warehouse_id == trimspace(task.warehouse_id) &&
      length(regexall("\\s", task.warehouse_id)) == 0,
      false
    )])
    error_message = "Each task must supply a nonblank warehouse_id without whitespace; use an existing Pro or serverless warehouse."
  }

  validation {
    condition = alltrue([for key, task in var.tasks : try(
      startswith(task.sql_file_path, "/") && length(task.sql_file_path) > 1 &&
      task.sql_file_path == trimspace(task.sql_file_path) && !endswith(task.sql_file_path, "/") &&
      length(regexall("[\\r\\n]", task.sql_file_path)) == 0 &&
      alltrue([for segment in slice(split("/", task.sql_file_path), 1, length(split("/", task.sql_file_path))) : !contains(["", ".", ".."], segment)]),
      false
    )])
    error_message = "Each sql_file_path must be an absolute WORKSPACE file path without empty, dot or parent segments, trailing slash, surrounding whitespace or newlines. A .sql suffix is not required."
  }

  validation {
    condition = alltrue([for key, task in var.tasks : try(
      alltrue([for dependency in task.depends_on : contains(keys(var.tasks), dependency) && dependency != key]),
      false
    )])
    error_message = "Task dependencies must reference existing task keys and must not reference the task itself."
  }

  validation {
    condition = alltrue([for key, task in var.tasks : try(
      alltrue([for name, value in task.parameters : length(trimspace(name)) > 0 && name == trimspace(name) && value != null]),
      false
    )])
    error_message = "SQL parameter names must be nonblank without surrounding whitespace and their values must not be null."
  }

  validation {
    condition = alltrue([for key, task in var.tasks : try(
      task.timeout_seconds >= 0 && floor(task.timeout_seconds) == task.timeout_seconds &&
      task.max_retries >= 0 && floor(task.max_retries) == task.max_retries &&
      task.min_retry_interval_millis >= 0 && floor(task.min_retry_interval_millis) == task.min_retry_interval_millis,
      false
    )])
    error_message = "Task timeout_seconds, max_retries and min_retry_interval_millis must be nonnegative integers; unlimited retries are not supported. Zero timeout means no task timeout."
  }
}

variable "parameters" {
  description = "Job-level parameter names and default string values. SQL task parameters are configured separately in tasks."
  type        = map(string)
  default     = {}
  nullable    = false

  validation {
    condition     = alltrue([for name, value in var.parameters : length(trimspace(name)) > 0 && name == trimspace(name) && value != null])
    error_message = "Job parameter names must be nonblank without surrounding whitespace and their default values must not be null."
  }
}

variable "run_as" {
  description = "Explicit execution identity: exactly one service_principal_name (application UUID, not SCIM ID) or user_name. Caller must arrange identity, run-as, file, warehouse and data permissions."
  type = object({
    service_principal_name = optional(string)
    user_name              = optional(string)
  })
  nullable = false

  validation {
    condition     = (var.run_as.service_principal_name != null) != (var.run_as.user_name != null)
    error_message = "run_as must specify exactly one of service_principal_name or user_name."
  }

  validation {
    condition     = var.run_as.service_principal_name == null ? true : can(regex("^[0-9A-Fa-f]{8}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{4}-[0-9A-Fa-f]{12}$", var.run_as.service_principal_name))
    error_message = "run_as.service_principal_name must be the service principal application UUID, not its SCIM ID."
  }

  validation {
    condition     = var.run_as.user_name == null ? true : length(trimspace(var.run_as.user_name)) > 0 && length(regexall("\\s", var.run_as.user_name)) == 0
    error_message = "run_as.user_name must be nonblank and contain no whitespace."
  }
}

variable "timeout_seconds" {
  description = "Job timeout in seconds; defaults to one hour. Set to 0 for no job timeout."
  type        = number
  default     = 3600
  nullable    = false

  validation {
    condition     = var.timeout_seconds >= 0 && floor(var.timeout_seconds) == var.timeout_seconds
    error_message = "timeout_seconds must be a nonnegative integer; 0 means no job timeout."
  }
}

variable "max_concurrent_runs" {
  description = "Maximum number of concurrent runs of the job."
  type        = number
  default     = 1
  nullable    = false

  validation {
    condition     = var.max_concurrent_runs >= 1 && floor(var.max_concurrent_runs) == var.max_concurrent_runs
    error_message = "max_concurrent_runs must be a positive integer."
  }
}

variable "schedule" {
  description = "Optional Quartz cron expression and timezone. Always created PAUSED; this module never enables scheduled execution. Omit for no schedule."
  type = object({
    quartz_cron_expression = string
    timezone_id            = string
  })
  default = null

  validation {
    condition = var.schedule == null ? true : try(
      length(trimspace(var.schedule.quartz_cron_expression)) > 0 && var.schedule.quartz_cron_expression == trimspace(var.schedule.quartz_cron_expression) &&
      length(trimspace(var.schedule.timezone_id)) > 0 && var.schedule.timezone_id == trimspace(var.schedule.timezone_id),
      false
    )
    error_message = "schedule must supply nonblank quartz_cron_expression and timezone_id without surrounding whitespace; the provider validates Quartz and timezone syntax."
  }
}
