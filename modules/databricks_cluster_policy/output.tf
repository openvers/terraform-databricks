output "cluster_policy_id" {
  description = "Databricks Cluster Policy ID"
  value       = databricks_cluster_policy.this.id
}

output "cluster_policy_name" {
  description = "Databricks Cluster Policy Name"
  value       = var.cluster_policy_name
}