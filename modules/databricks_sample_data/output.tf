output "file_paths" {
  description = "Sample volume file paths keyed by fixed dataset identity."
  value       = { for name, file in databricks_file.this : name => file.path }
}
