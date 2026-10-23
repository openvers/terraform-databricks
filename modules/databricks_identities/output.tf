output "group_names" {
  description = "Account group display names keyed by caller-provided logical group identity. Workspace consumers must also wait for workspace assignments and entitlements."
  value = {
    for group_key, group in module.databricks_account_group :
    group_key => group.databricks_group_name
  }
}
