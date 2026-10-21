output "databricks_token" {
  value     = databricks_token.this.token_value
  sensitive = true
}