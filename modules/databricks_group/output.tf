output "databricks_group_name" {
  description = "Databricks Group/Team Name"
  value       = databricks_group.this.display_name
}

output "databricks_group_id" {
  description = "Databricks Group ID"
  value = databricks_group.this.id
}

output "databricks_group_external_id" {
  description = "Databricks Group External ID"
  value = databricks_group.this.external_id
}