terraform {
  required_version = ">= 1.9"

  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [
        databricks.accounts,
        databricks.workspace
      ]
    }
  }
}

locals {
  databricks_groups = {
    for group_key, group in var.databricks_groups :
    group_key => merge(group, {
      group_id = module.databricks_account_group[group_key].databricks_group_id
    })
  }

  workspace_assignments = merge(
    {},
    [
      for group_key, group in local.databricks_groups : {
        for assignment_key, assignment in group.workspace_assignments :
        jsonencode([group_key, assignment_key]) => merge(assignment, {
          group_id = group.group_id
        })
      }
    ]...
  )

  workspace_entitlements = {
    for group_key, group in local.databricks_groups :
    group_key => merge(group.workspace_entitlements, {
      group_id = group.group_id
    })
    if group.workspace_entitlements != null
  }
}

module "databricks_account_group" {
  source = "../databricks_accounts/modules/databricks_group"

  for_each = var.databricks_groups

  group_name = each.value.name
  members    = each.value.members

  providers = {
    databricks.accounts = databricks.accounts
  }
}


module "databricks_workspace_assignment" {
  source = "../databricks_accounts/modules/databricks_workspace_assignment"

  for_each = local.workspace_assignments

  principal_id = each.value.group_id
  workspace_id = each.value.workspace_id
  permission   = each.value.permission

  providers = {
    databricks.accounts = databricks.accounts
  }
}

module "databricks_workspace_entitlements" {
  source = "../databricks_workspace/modules/databricks_entitlements"

  for_each = local.workspace_entitlements

  depends_on = [module.databricks_workspace_assignment]

  group_id                   = each.value.group_id
  workspace_access           = try(each.value.workspace_access, false)
  databricks_sql_access      = try(each.value.databricks_sql_access, false)
  allow_cluster_create       = try(each.value.allow_cluster_create, false)
  allow_instance_pool_create = try(each.value.allow_instance_pool_create, false)

  providers = {
    databricks.workspace = databricks.workspace
  }
}
