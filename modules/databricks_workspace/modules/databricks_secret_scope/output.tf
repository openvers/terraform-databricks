output "databricks_secret_scope" {
  description = "Databricks Secret Scope"
  value       = var.secret_scope
}

output "databricks_secret_scope_id" {
  description = "Databricks Secret Scope"
  value       = databricks_secret_scope.this.id
}