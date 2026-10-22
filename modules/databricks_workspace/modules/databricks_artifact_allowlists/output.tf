output "artifact_allowlist_ids" {
  description = "Managed artifact allowlist IDs keyed by artifact type."
  value = {
    for artifact_type, allowlist in databricks_artifact_allowlist.this : artifact_type => allowlist.id
  }
}
