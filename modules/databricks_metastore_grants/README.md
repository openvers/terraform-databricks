# Metastore grants

Manages the complete authoritative grants for an existing, assigned Unity Catalog
metastore using only the `databricks.workspace` provider alias. Creates no
metastore, assignment, identity, storage, credential or catalog and requires no
account provider. Terraform >= 1.2.0 is required.

## Ownership and clearing

Use exactly **one authoritative Terraform grants manager per metastore**, not one
per workspace. Multiple workspaces attached to the same metastore share these
grants: separate managers conflict and overwrite each other's changes. Do not
manage overlapping metastore grants through other resources, states or manual
changes. Aggregate every caller's required grants into this module's `grants`
list, combining privileges into one entry per principal. Include the managing
identity's required grants so it does not revoke its own access.

`grants = []` (the default) does **not** skip management. The unconditional
`databricks_grants.this` remains authoritative and revokes existing metastore
grants. Removing a principal or privilege revokes that access; destroying this
resource also revokes grants. Review these destructive effects before applying.
This does not transfer metastore ownership or remove owner-derived rights.

## Composition

Example inside a caller that already has the shared modules available locally;
the sibling source is relative to that caller's module directory:

```hcl
module "metastore_grants" {
  source = "../databricks_metastore_grants"

  providers = {
    databricks.workspace = databricks.workspace
  }

  metastore_id = module.metastore_assignment.ready_metastore_id
  grants = [
    {
      principal  = "Data Engineers"
      privileges = ["CREATE_CATALOG", "CREATE_STORAGE_CREDENTIAL"]
    }
  ]
}
```

Configure the workspace provider for the workspace attached to the supplied
metastore, with an identity authorized to manage its grants. For newly created
metastores/workspaces, pass the assignment module's `ready_metastore_id`, not a
creation-only ID: this preserves assignment and optional propagation-delay
ordering. That delay is not a runtime readiness check.

Inputs:

- `metastore_id`: required nonblank string without surrounding whitespace.
- `grants`: non-null `list(object({ principal = string, privileges = set(string) }))`,
  default `[]`. Principals must be unique, nonblank and without surrounding
  whitespace. Each privileges set must be nonempty with nonblank strings without
  surrounding whitespace. Use provider/API-supported metastore privilege names
  with underscores; the module intentionally does not freeze a privilege enum.
  Principals must already exist; unknown principal values may resolve at apply.

The dynamic grant blocks iterate the input list directly, never a map keyed by
apply-time principal IDs. Duplicate-principal validation defers when values are
unknown and must pass when they resolve.

Outputs:

- `grants_id`: the provider's grants resource ID.
- `metastore_id`: the metastore ID with a dependency on grants management. Use it
  for downstream storage-credential ordering, or explicitly depend on this module
  when the downstream resource has no metastore ID input. It is an ordering token,
  not proof of API readiness or authorization propagation.
