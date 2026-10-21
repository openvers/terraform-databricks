output "warehouse_id" {
  description = "SQL warehouse ID for jobs and other consumers."
  value       = databricks_sql_endpoint.this.id
}

output "jdbc_url" {
  description = "SQL warehouse JDBC connection URL."
  value       = databricks_sql_endpoint.this.jdbc_url
}