terraform {
  required_providers {
    databricks = {
      source                = "databricks/databricks"
      configuration_aliases = [databricks.workspace]
    }
  }
}

locals {
  artifact_allowlist_matchers_by_type = {
    for matcher in var.artifact_allowlist_requests : matcher.artifact_type => jsonencode({
      artifact   = matcher.artifact
      match_type = matcher.match_type
    })...
  }

  artifact_allowlists = {
    for artifact_type, matchers in local.artifact_allowlist_matchers_by_type :
    artifact_type => toset(matchers)
  }
}

resource "databricks_artifact_allowlist" "this" {
  provider = databricks.workspace
  for_each = {
    for artifact_type, matchers in local.artifact_allowlists : artifact_type => matchers
    if var.manage_artifact_allowlists
  }

  artifact_type = each.key

  dynamic "artifact_matcher" {
    for_each = each.value

    content {
      artifact   = jsondecode(artifact_matcher.value).artifact
      match_type = jsondecode(artifact_matcher.value).match_type
    }
  }
}
