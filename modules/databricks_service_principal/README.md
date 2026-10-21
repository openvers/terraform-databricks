# Databricks service principal

Creates a Databricks-managed account service principal using the caller's account-level provider. Existing identities must be explicitly imported; the module does not implicitly adopt them.

Requires Terraform >= 1.2.0 and a caller-configured `databricks/databricks` provider supplied through the `databricks.accounts` alias. This module does not create an external cloud identity registration, credentials, group memberships, roles, or workspace assignments.

## Inputs

| Name | Type | Default | Description |
| --- | --- | --- | --- |
| `display_name` | `string` | Required | Non-null, nonempty display name without surrounding whitespace or tab/newline characters. |
| `permanently_delete_on_destroy` | `bool` | `false` | Non-null. By default, removing the resource deactivates the identity (`disable_as_user_deletion = true`). Set to `true` to permanently delete it instead. |

## Outputs and identity types

| Name | Description |
| --- | --- |
| `databricks_service_principal_id` | Databricks account **SCIM ID**, for group memberships and workspace assignments. Its meaning is unchanged. |
| `databricks_service_principal_display_name` | Service principal display name. |
| `databricks_service_principal_application_id` | Service principal **application UUID**, for job `run_as.service_principal_name` and application-ID-based grants. Not the SCIM ID and not a credential. |

For a SQL-file job, use `databricks_service_principal_application_id` as the run-as value, never the SCIM ID. Exposing this additive output does not change identity creation, adoption, deletion behavior, or the existing outputs.

The caller must independently arrange workspace assignment and activation, required SQL entitlements, warehouse access, workspace SQL file read access, and catalog/schema/data grants. Workspace assignment alone does not imply those permissions. The deployer also needs the `servicePrincipal/user` role to set this principal as a job's run-as identity. This module grants none of these permissions.
