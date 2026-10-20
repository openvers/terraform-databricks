terraform {
  required_version = ">= 1.2.0"

  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.accounts]
    }
    time = {
      source = "hashicorp/time"
    }
  }
}

resource "databricks_metastore_assignment" "this" {
  provider     = databricks.accounts
  metastore_id = var.metastore_id
  workspace_id = var.workspace_id
}

# This bounded delay is an ordering barrier, not a runtime readiness check.
resource "time_sleep" "propagation" {
  count = var.propagation_delay_seconds > 0 ? 1 : 0

  create_duration = "${var.propagation_delay_seconds}s"
  triggers = {
    assignment_id = databricks_metastore_assignment.this.id
    metastore_id  = databricks_metastore_assignment.this.metastore_id
    workspace_id  = tostring(databricks_metastore_assignment.this.workspace_id)
  }

  depends_on = [databricks_metastore_assignment.this]
}
