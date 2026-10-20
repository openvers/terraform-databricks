output "assignment_id" {
  description = "Assignment resource ID; does not wait for the optional propagation delay."
  value       = databricks_metastore_assignment.this.id
}

output "metastore_id" {
  description = "Assigned metastore ID; does not wait for the optional propagation delay."
  value       = databricks_metastore_assignment.this.metastore_id
}

output "workspace_id" {
  description = "Assigned numeric Databricks workspace ID."
  value       = databricks_metastore_assignment.this.workspace_id
}

output "ready_metastore_id" {
  description = "Assigned metastore ID after the optional delay; an ordering token, not proof of runtime readiness."
  value       = databricks_metastore_assignment.this.metastore_id
  depends_on  = [time_sleep.propagation]
}
