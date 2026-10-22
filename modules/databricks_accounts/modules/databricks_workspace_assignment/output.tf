output "databricks_workspace_assignment_id" {
  description = "Databricks Workspace Permission Assignment ID in workspace_id|principal_id Form"
  value       = databricks_mws_permission_assignment.this.id
}

output "databricks_workspace_assignment_principal_id" {
  description = "Databricks Account Principal SCIM ID Assigned to the Workspace"
  value       = tostring(databricks_mws_permission_assignment.this.principal_id)
}

output "databricks_workspace_assignment_workspace_id" {
  description = "Numeric Databricks Workspace ID for This Assignment"
  value       = databricks_mws_permission_assignment.this.workspace_id
}

output "databricks_workspace_assignment_permission" {
  description = "Databricks Workspace Permission Applied by This Assignment"
  value       = one(databricks_mws_permission_assignment.this.permissions)
}
