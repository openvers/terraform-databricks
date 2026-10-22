variable "artifact_allowlist_requests" {
  description = "Complete metastore-scoped artifact matcher requests, grouped and deduplicated by artifact type. Use plan-known artifact paths or Maven coordinates."
  type = list(object({
    artifact_type = string
    artifact      = string
    match_type    = string
  }))
  default  = []
  nullable = false

  validation {
    condition = try(alltrue([
      for matcher in var.artifact_allowlist_requests :
      contains(["INIT_SCRIPT", "LIBRARY_JAR", "LIBRARY_MAVEN"], matcher.artifact_type)
    ]), false)
    error_message = "Artifact allowlist artifact_type must be INIT_SCRIPT, LIBRARY_JAR, or LIBRARY_MAVEN."
  }

  validation {
    condition = try(alltrue([
      for matcher in var.artifact_allowlist_requests : matcher.match_type == "PREFIX_MATCH"
    ]), false)
    error_message = "Artifact allowlist match_type must be PREFIX_MATCH."
  }

  validation {
    condition = try(alltrue([
      for matcher in var.artifact_allowlist_requests : trimspace(matcher.artifact) != ""
    ]), false)
    error_message = "Artifact allowlist artifact must be non-null and nonblank."
  }
}

variable "manage_artifact_allowlists" {
  description = "Whether to own complete allowlists for the requested artifact types. When false, an external owner must supply all matchers and readiness. This flag does not migrate existing state or ownership."
  type        = bool
  default     = true
  nullable    = false
}
