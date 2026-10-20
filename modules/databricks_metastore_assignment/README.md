# Metastore assignment

Assigns an existing metastore to an existing workspace using only the
`databricks.accounts` account-scoped provider alias. Requires Terraform >= 1.2
and the `databricks/databricks` and `hashicorp/time` providers. Creates no
metastore, catalog, grants, identity or storage, and needs no workspace provider
or external account/workspace properties.

## Contract

| Input | Type | Requirement/default |
| --- | --- | --- |
| `metastore_id` | string | Required, nonblank with no surrounding whitespace |
| `workspace_id` | number | Required integer, 1 through 9223372036854775807 (not an ARM resource ID) |
| `propagation_delay_seconds` | number | Integer 0 through 600; default 10, zero bypasses delay |

Outputs: `assignment_id`, `metastore_id`, `workspace_id` and `ready_metastore_id`.
Use `ready_metastore_id` for downstream workspace grants: it depends on the
entire optional delay collection, including when the delay is bypassed. Other
outputs do not wait for the delay. Assignment ID, metastore ID or workspace ID
changes replace the delay barrier. Changing only a positive delay duration does
not repeat an already completed wait.

The delay is not a runtime readiness check, poll or guarantee that workspace
APIs have converged. Consumers may still require provider retries or separately
verified readiness handling.

## Composition pattern

Illustrative repository-root local composition (not a published remote source).
Configure authentication outside this example; the workspace provider is used
only by the consumer, not by this module.

```hcl
provider "databricks" {
  alias      = "accounts"
  host       = var.databricks_account_host
  account_id = var.databricks_account_id
}

provider "databricks" {
  alias = "workspace"
  host  = var.workspace_host
}

module "assignment" {
  source = "./modules/databricks_metastore_assignment"
  providers = {
    databricks.accounts = databricks.accounts
  }

  metastore_id = var.metastore_id
  workspace_id = var.workspace_id
}

# Use one authoritative grants owner for this metastore.
resource "databricks_grants" "metastore" {
  provider  = databricks.workspace
  metastore = module.assignment.ready_metastore_id

  grant {
    principal  = var.existing_account_group
    privileges = ["CREATE_CATALOG"]
  }
}
```

## Assignment and adoption limits

Account assignment creation uses POST, not PUT. Idempotent creation when the
workspace is already assigned (including automatic assignment) is not
established. Do not assume this module adopts an existing assignment: verify
the actual assignment and provider import contract, then obtain explicit review
and authorization before any import. This module performs no implicit import.

The deprecated `default_catalog_name` field is omitted: no default catalog is
created or chosen. This module does not disable automatic Unity Catalog
onboarding and introduces no automatic opt-out controls.
