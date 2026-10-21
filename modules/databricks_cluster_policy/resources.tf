terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DEFAULT DATABRICKS CLUSTER POLICY LOCAL BLOCK
##
## This local block defines a default Databricks Cluster Policy to be applied later
## to the cluster
## ---------------------------------------------------------------------------------------------------------------------
locals {
  default_policy = {
    "dbus_per_hour": {
      "type": "range",
      "maxValue": var.dbus_per_hour
    },
    "autotermination_minutes": {
      "type": "fixed",
      "value": var.instance_pool_autotermination,
      "hidden": true
    },
    "custom_tags.Team": {
      "type": "fixed",
      "value": var.group_name
    },
    "data_security_mode": {
      "type": "fixed",
      "value": var.data_security_mode,
      "hidden": true
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS CLUSTER POLICY RESOURCE
##
## This resource block defines a Databricks cluster policy.
## 
## Parameters:
## - `cluster_policy_name`: Name of the cluster policy. Example: "policy-1"
## - `default_policy`: Default policy settings. Example: { "dbus_per_hour": { "type": "range", "maxValue": 10 }, ... }
## - `policy_overrides`: Overrides for default policy settings. Example: { "dbus_per_hour": { "type": "fixed", "value": 5 }, ... }
## - `max_clusters_per_user`: Maximum number of clusters a user can create. Example: 5
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_cluster_policy" "this" {
  provider              = databricks.workspace

  name                  = var.cluster_policy_name
  definition            = jsonencode(merge(local.default_policy, var.policy_overrides))
  max_clusters_per_user = var.max_clusters_per_user
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS PERMISSIONS RESOURCE
##
## This resource block defines permissions for a Databricks cluster policy.
## 
## Parameters:
## - `cluster_policy_id`: ID of the Databricks cluster policy. Example: "12345678"
## - `group_name`: Name of the group for which permissions are defined. Example: "engineer_group"
## - `permission_level`: Level of permission granted to the group. Example: "CAN_VIEW"
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_permissions" "this" {
  provider          = databricks.workspace
  
  cluster_policy_id = databricks_cluster_policy.this.id
  access_control {
    group_name       = var.group_name
    permission_level = var.group_permission
  }
}
