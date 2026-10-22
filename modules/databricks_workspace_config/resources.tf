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
  databricks_group_names = var.databricks_existing_groups

  secret_values = {
    for secret in var.databricks_secrets :
    secret.secret_name => secret.secret_value
  }
}

module "databricks_secret_scope" {
  source = "../databricks_workspace/modules/databricks_secret_scope"
  count  = var.manage_secret_scope ? 1 : 0

  secret_scope = var.databricks_secret_scope

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_secret" {
  source = "../databricks_workspace/modules/databricks_secret"

  # Only names are exposed as addresses; secret values remain sensitive.
  for_each = var.manage_databricks_secrets ? nonsensitive(toset(keys(local.secret_values))) : toset([])

  secret_scope_id = var.manage_secret_scope ? module.databricks_secret_scope[0].databricks_secret_scope_id : var.databricks_secret_scope
  secret_name     = each.key
  secret_data     = local.secret_values[each.key]

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS WORKSPACE ACCESS TOKEN MODULE
## 
## This module creates a Databricks Person Access Token (PAT) an Azure Databricks workspace. This token can be used to
## authenticate with the Databricks Workspace via CLI/Curl without needing to pass Service Principal Credentials.
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_workspace_access_token" {
  source = "../databricks_workspace/modules/databricks_pat_token"
  count  = var.create_databricks_access_token ? 1 : 0

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS DRIVER NODE INSTANCE POOL MODULE
## 
## This module creates an instance pool in a Databricks workspace specifically for driver nodes.
## 
## Parameters:
## - `instance_pool_name`: Specifies the name of the instance pool
## - `instance_pool_max_capacity`: Specifies the maximum capacity of the instance pool
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_instance_pool" {
  source   = "../databricks_workspace/modules/databricks_instance_pool"
  for_each = var.databricks_instance_pools

  instance_pool_name         = each.value.name
  instance_pool_max_capacity = each.value.max_capacity

  providers = {
    databricks.workspace = databricks.workspace
  }
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CLUSTER POLICY MODULE
## 
## This module sets up a cluster policy in a Databricks workspace.
## 
## Parameters:
## - `cluster_policy_name`: Specifies the name of the cluster policy.
## - `group_name`: Specify the name of the engineer group to associate the policy with.
## - `data_security_mode`: Databrick cluster security mode
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_cluster_policy" {
  source   = "../databricks_workspace/modules/databricks_cluster_policy"
  for_each = var.databricks_clusters

  depends_on = [
    module.databricks_instance_pool,
  ]

  cluster_policy_name           = "${each.key}-policy"
  group_name                    = local.databricks_group_names[each.value.policy.group]
  group_permission              = each.value.policy.group_permission
  max_clusters_per_user         = each.value.policy.max_clusters_per_user
  dbus_per_hour                 = each.value.policy.dbus_per_hour
  instance_pool_autotermination = each.value.policy.autotermination_minutes
  data_security_mode            = each.value.policy.data_security_mode

  providers = {
    databricks.workspace = databricks.workspace
  }
}


module "databricks_catalog_config" {
  source = "../databricks_workspace/modules/databricks_catalog_config"

  phase                     = "storage"
  databricks_catalog_config = var.databricks_catalog_config

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_artifact_allowlists" {
  source = "../databricks_workspace/modules/databricks_artifact_allowlists"

  depends_on = [
    module.databricks_catalog_config,
    module.databricks_sample_data,
  ]

  artifact_allowlist_requests = concat(
    flatten([
      for cluster in values(var.databricks_clusters) : values(cluster.library_paths)
    ]),
    flatten([
      for artifact_type, matchers in var.databricks_artifact_allowlists : [
        for matcher in matchers : {
          artifact_type = artifact_type
          artifact      = matcher.artifact
          match_type    = matcher.match_type
        }
      ]
    ])
  )
  manage_artifact_allowlists = var.manage_artifact_allowlists

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_catalog_tables" {
  source = "../databricks_workspace/modules/databricks_catalog_config"

  databricks_catalog_config = var.databricks_catalog_config
  phase                     = "tables"
  cluster_ids = {
    for key, cluster in module.databricks_cluster : key => cluster.databricks_cluster_id
  }

  depends_on = [
    module.databricks_catalog_config,
    module.databricks_sample_data,
    module.databricks_cluster,
  ]

  providers = {
    databricks.workspace = databricks.workspace
  }
}

module "databricks_sample_data" {
  source = "../databricks_workspace/modules/databricks_sample_data"

  databricks_catalog_config = var.databricks_catalog_config

  depends_on = [module.databricks_catalog_config]

  providers = {
    databricks.workspace = databricks.workspace
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CLUSTER MODULE
## 
## This module sets up a Databricks cluster with the specified configurations.
## 
## Parameters:
## - `cluster_name`: Specify the name of the Databricks cluster.
## - `node_instance_pool_id`: Specify the instance pool IDs for worker nodes.
## - `driver_instance_pool_id`: Specify the instance pool IDs for driver nodes.
## - `cluster_policy_name`: Specify the name of the cluster policy.
## - `cluster_policy_id`: Specify the ID of the cluster policy.
## - `library_paths`: Library Volume to be included in the ALLOWED LIST on Databricks Cluster
## - `jar_libraries`: Volume paths to jar libraries to be installed on Databricks Cluster
## - `whl_libraries`: Volume paths to whl libraries to be installed on Databricks Cluster
## - `spark_env_variable`: Define Spark environment variables.
## - `spark_conf_variable`: Define Spark configuration variables.
## - `azure_attributes`: Azure compute configurations for Databricks Clusters
## ---------------------------------------------------------------------------------------------------------------------
module "databricks_cluster" {
  source   = "../databricks_workspace/modules/databricks_cluster"
  for_each = var.databricks_clusters

  depends_on = [module.databricks_catalog_config, module.databricks_artifact_allowlists]

  cluster_name            = each.key
  node_instance_pool_id   = module.databricks_instance_pool["node"].instance_pool_id
  driver_instance_pool_id = module.databricks_instance_pool["driver"].instance_pool_id

  cluster_policy_name = module.databricks_cluster_policy[each.key].cluster_policy_name
  cluster_policy_id   = module.databricks_cluster_policy[each.key].cluster_policy_id

  num_workers_min = each.value.num_workers_min
  num_workers_max = each.value.num_workers_max

  library_paths = {}
  jar_libraries = each.value.jar_libraries
  whl_libraries = each.value.whl_libraries

  spark_env_variable  = each.value.spark_env_variable
  spark_conf_variable = each.value.spark_conf_variable
  azure_attributes    = each.value.azure_attributes
  aws_attributes      = each.value.aws_attributes

  providers = {
    databricks.workspace = databricks.workspace
  }
}


module "databricks_sql_warehouse" {
  source   = "../databricks_workspace/modules/databricks_sql_warehouse"
  for_each = var.databricks_sql_warehouses

  # The caller must ensure referenced groups are assigned and ready in this workspace.

  warehouse_name = each.value.name
  config         = each.value
  group_names    = local.databricks_group_names

  providers = {
    databricks.workspace = databricks.workspace
  }
}
