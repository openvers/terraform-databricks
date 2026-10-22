output "databricks_entitlements_id" {
  description = "ID of the managed workspace entitlements."
  value       = databricks_entitlements.this.id
}

output "databricks_group_id" {
  description = "ID of the group receiving workspace entitlements."
  value       = databricks_entitlements.this.group_id
}
