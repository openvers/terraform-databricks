output "databricks_service_principal_id" {
  description = "Databricks Account Service Principal SCIM ID for Group Memberships and Workspace Assignments"
  value       = databricks_service_principal.this.id
}

output "databricks_service_principal_display_name" {
  description = "Databricks Account Service Principal Display Name"
  value       = databricks_service_principal.this.display_name
}

output "databricks_service_principal_application_id" {
  description = "Service principal application UUID for job run_as and application-ID-based grants; not the SCIM ID and not a credential."
  value       = databricks_service_principal.this.application_id
}
