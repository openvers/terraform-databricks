# Account metastore creation

Creates only an account-scoped Unity Catalog metastore, independently of any
workspace. Assignment and workspace grants are separate modules; there is no
retained combined/legacy mode. Requires Terraform **>= 1.2.0** and the
`databricks/databricks` provider, mapped through `databricks.accounts`.
No workspace provider, identity, account-admin grant, storage, credential or
catalog is created by this module.

## Contract

| Input | Type | Requirement/default |
| --- | --- | --- |
| `cloud_region` | string | Required account metastore region |
| `databricks_metastore_name` | string | Default `"Primary"` |
| `databricks_unity_admin_group` | string or null | Default `null`; optional preexisting account principal used as owner |
| `databricks_storage_root` | string or null | Default `null`; omits the storage root when unset |
| `force_destroy` | bool | Default `false`; permits deletion of a nonempty metastore only when explicitly enabled |

Strings must be nonblank with no surrounding whitespace when supplied. Only
owner and storage root accept null. Despite its retained name,
`databricks_unity_admin_group` accepts an existing account username, group name
or service-principal application ID. It creates no principal. Null omits the
owner argument and leaves ownership selection to the backend; it does **not**
guarantee caller ownership. Review the selected owner and the caller's authority.
Never derive this input from a group created in the future workspace: that
would reintroduce the bootstrap dependency the split removes.

Resource address `databricks_metastore.this` and output `metastore_id` are
retained. The output indicates creation, **not** workspace assignment readiness.
The previous hardcoded `force_destroy = true` is replaced by the safe default
`false`; enabling it is a separately reviewed destructive choice.

Removed from this module:

- `databricks_workspace_id`: now numeric `workspace_id` in the assignment module.
- `databricks_metastore_grants`: now `grants` in the grants module.
- `databricks_catalog_name`: removed, not forwarded. The assignment module omits
  deprecated `default_catalog_name` and does not select or create a catalog.
- Provider alias `databricks.workspace`, the assignment resource, propagation
  sleep and workspace grants. Pass each alias only to its appropriate module.

## Composition

This illustrative caller belongs at the **root of this repository**, so all
three local sources resolve relative to that root, not relative to this README.
It is not a portable remote-source recommendation or a published release.
Supply the referenced variables and an independently provisioned workspace ID
and host; for a newly created workspace, use its outputs instead.

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

module "metastore" {
  source = "./modules/databricks_metastore"
  providers = {
    databricks.accounts = databricks.accounts
  }

  cloud_region = var.cloud_region
  # Owner/storage root omitted; backend selects owner. force_destroy stays false.
}

module "metastore_assignment" {
  source = "./modules/databricks_metastore_assignment"
  providers = {
    databricks.accounts = databricks.accounts
  }

  metastore_id              = module.metastore.metastore_id
  workspace_id              = var.workspace_id # Numeric Databricks ID, not ARM ID.
  propagation_delay_seconds = 10
}

module "metastore_grants" {
  source = "./modules/databricks_metastore_grants"
  providers = {
    databricks.workspace = databricks.workspace
  }

  metastore_id = module.metastore_assignment.ready_metastore_id
  grants = [{
    principal  = var.existing_account_group
    privileges = ["CREATE_CATALOG", "CREATE_STORAGE_CREDENTIAL"]
  }]
}
```

Keep existing authentication configuration outside this example. Account
provider bootstrap must be independent of workspace-created identities, secrets
and host. A new workspace must depend on **foundation creation only**, not on
assignment, grants or the old combined module. Intended ordering is foundation
-> workspace -> assignment readiness -> grants -> workspace configuration.

Assignment requires `metastore_id` and a numeric `workspace_id` (positive signed
64-bit integer). Its integer delay defaults to 10 seconds, accepts 0..600 and
can be bypassed with zero. `ready_metastore_id` waits for that optional barrier;
it is not a runtime readiness check. Grants require `metastore_id`; `grants` is
an authoritative list of `{ principal, privileges }` mappings, defaulting to
`[]`. **Empty grants clear existing grants**, not skip management. Use only one
authoritative grants manager per metastore, even across multiple workspaces.

Account assignment creation uses POST; idempotent adoption of an already
automatically assigned workspace is unverified. Any adoption requires a
separately reviewed import after inspection. No universal automatic Unity
Catalog onboarding opt-out is provided or guaranteed.

See the [migration guide](../../docs/owned-metastore-split-migration.md) before
upgrading an existing caller. Shared HCL separation does not mean Azure wiring
or a shared release is published: those remain separately gated. AWS/GCP
consumers stay on their existing pins until a deliberate migration.
