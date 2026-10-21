output "id" {
  description = "ID of the Databricks job."
  value       = databricks_job.this.id
}

output "url" {
  description = "Workspace URL of the Databricks job."
  value       = databricks_job.this.url
}
