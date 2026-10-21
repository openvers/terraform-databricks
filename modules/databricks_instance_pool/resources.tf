terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS SPARK VERSION DATA SOURCE
##
## This data source retrieves information about the latest available Spark version from Databricks.
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_spark_version" "latest" {
  provider = databricks.workspace
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS NODE TYPE DATA SOURCE
##
## This data source retrieves information about the Databricks node types based on specified criteria.
## 
## Parameters:
## - `min_memory_gb`: The minimum memory (in gigabytes) required for the nodes. Example: "8"
## - `min_cores`: The minimum number of CPU cores required for the nodes. Example: "4"
## - `category`: The category of nodes to filter. Example: "Standard_DS_v2"
## ---------------------------------------------------------------------------------------------------------------------
data "databricks_node_type" "this" {
  provider      = databricks.workspace

  min_memory_gb = var.node_min_memory_gb
  min_cores     = var.node_min_cores
  category      = var.node_category
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS INSTANCE POOL RESOURCE
##
## This resource defines an instance pool in Databricks.
## 
## Parameters:
## - `instance_pool_name`: The name of the instance pool. Example: "my-instance-pool"
## - `min_idle_instances`: The minimum number of idle instances to keep in the pool. Example: 1
## - `max_capacity`: The maximum number of instances allowed in the pool. Example: 10
## - `node_type_id`: The ID of the node type to use in the pool.
## - `idle_instance_autotermination_minutes`: The number of minutes after which idle instances are terminated. Example: 60
## - `preloaded_spark_versions`: List of preloaded Spark versions for the instance pool.
## - `aws_attributes`: Optional dynamic block for AWS-specific attributes.
##   - `availability`: Availability type for AWS instances.
##   - `spot_bid_price_percent`: Percentage of the On-Demand price to bid for Spot instances.
## - `azure_attributes`: Optional dynamic block for Azure-specific attributes.
##   - `availability`: Availability type for Azure instances.
##   - `spot_bid_max_price`: The maximum price for Spot instances in Azure.
## - `gcp_attributes`: Optional dynamic block for GCP-specific attributes.
##   - `gcp_availability`: Availability type for GCP instances.
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_instance_pool" "this" {
  provider                              = databricks.workspace
  
  instance_pool_name                    = var.instance_pool_name
  min_idle_instances                    = var.instance_pool_min_idle_instances
  max_capacity                          = var.instance_pool_max_capacity
  node_type_id                          = data.databricks_node_type.this.id
  idle_instance_autotermination_minutes = var.instance_pool_autotermination
  preloaded_spark_versions              = [
    data.databricks_spark_version.latest.id
  ]
  
  dynamic "aws_attributes" {
    for_each = var.aws_attributes

    content {
      availability           = aws_attributes.availability
      spot_bid_price_percent = aws_attributes.spot_bid_price_percent
    }
  }

  dynamic "azure_attributes" {
    for_each = var.azure_attributes

    content {
      availability       = azure_attributes.availability
      spot_bid_max_price = azure_attributes.spot_bid_max_price
    }
  }

  dynamic "gcp_attributes" {
    for_each = var.gcp_attributes

    content {
      gcp_availability = gcp_attributes.gcp_availability
    }
  }
}
