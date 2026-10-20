output "grants_id" {
  description = "ID of the authoritative metastore grants resource."
  value       = databricks_grants.this.id
}

output "metastore_id" {
  description = "Metastore ID after grants management; an ordering token for downstream credentials, not a runtime readiness check."
  value       = databricks_grants.this.metastore
  depends_on  = [databricks_grants.this]
}
