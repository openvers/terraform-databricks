output "databricks_cluster_id" {
  description = "Databricks All-Purpose Computer Cluster ID"
  value       = databricks_cluster.this.id
}