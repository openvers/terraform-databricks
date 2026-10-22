output "group_names" {
  description = "Account group display names keyed by logical group identity, including __default_admin. Workspace consumers must also wait for workspace assignments and entitlements."
  value = {
    for group_key, group in module.databricks_account_group :
    group_key => group.databricks_group_name
  }
}

output "default_service_principal_id" {
  description = "Default service principal SCIM ID for group memberships and workspace assignments."
  value       = module.default_service_principal.databricks_service_principal_id
}

output "default_service_principal_application_id" {
  description = "Default service principal application UUID; not a credential."
  value       = module.default_service_principal.databricks_service_principal_application_id
}

output "default_service_principal_display_name" {
  description = "Display name of the default account service principal."
  value       = module.default_service_principal.databricks_service_principal_display_name
}
