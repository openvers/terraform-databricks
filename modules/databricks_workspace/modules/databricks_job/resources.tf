terraform {
  required_version = ">= 1.5.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
  }
}

resource "databricks_job" "this" {
  provider = databricks.workspace

  name                = var.name
  description         = var.description
  tags                = var.tags
  timeout_seconds     = var.timeout_seconds
  max_concurrent_runs = var.max_concurrent_runs

  run_as {
    service_principal_name = var.run_as.service_principal_name
    user_name              = var.run_as.user_name
  }

  dynamic "parameter" {
    for_each = sort(keys(var.parameters))
    content {
      name    = parameter.value
      default = var.parameters[parameter.value]
    }
  }

  dynamic "task" {
    for_each = sort(keys(var.tasks))
    content {
      task_key                  = task.value
      timeout_seconds           = var.tasks[task.value].timeout_seconds
      max_retries               = var.tasks[task.value].max_retries
      min_retry_interval_millis = var.tasks[task.value].min_retry_interval_millis
      retry_on_timeout          = var.tasks[task.value].retry_on_timeout

      dynamic "depends_on" {
        for_each = sort(tolist(var.tasks[task.value].depends_on))
        content {
          task_key = depends_on.value
        }
      }

      sql_task {
        warehouse_id = var.tasks[task.value].warehouse_id
        parameters   = var.tasks[task.value].parameters
        file {
          path   = var.tasks[task.value].sql_file_path
          source = "WORKSPACE"
        }
      }
    }
  }

  dynamic "schedule" {
    for_each = var.schedule == null ? [] : [var.schedule]
    content {
      quartz_cron_expression = schedule.value.quartz_cron_expression
      timezone_id            = schedule.value.timezone_id
      pause_status           = "PAUSED"
    }
  }
}
