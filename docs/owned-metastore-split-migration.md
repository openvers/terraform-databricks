# Owned metastore split: reviewed migration

This is a breaking split, not a compatibility switch. The shared HCL is
logically separated into creation, account assignment and workspace grants.
Azure wiring and publication of an approved shared reference are separate gates;
this guide does not claim those steps are complete. Do not replace portable
sources with machine-local sibling paths or invent a published SHA. AWS/GCP
consumers remain pinned to their old versions; upgrading them requires a
separate, deliberate migration.

## New contracts and ordering

All three modules require Terraform >= 1.2.0.

| Module | Provider aliases | Inputs / behavior |
| --- | --- | --- |
| `databricks_metastore` | `databricks.accounts` only | Required `cloud_region`; name defaults to `Primary`; nullable owner `databricks_unity_admin_group` and `databricks_storage_root` default to null; `force_destroy` defaults false |
| `databricks_metastore_assignment` | `databricks.accounts` only; also requires `hashicorp/time` | Required `metastore_id`, numeric `workspace_id`; integer `propagation_delay_seconds` defaults to 10, range 0..600 |
| `databricks_metastore_grants` | `databricks.workspace` only | Required `metastore_id`; authoritative `grants` defaults to `[]` |

Creation no longer accepts `databricks_workspace_id`,
`databricks_metastore_grants` or `databricks_catalog_name`, nor the workspace
provider alias. Move workspace ID and grant mappings to the new modules under
their new names. There is no combined mode. The deprecated assignment
`default_catalog_name` is omitted, not replaced with a placeholder catalog;
catalog/default namespace management is separate.

The retained owner variable name does not mean a workspace admin group is
created. Supply only an optional **preexisting account principal** (username,
group name or service-principal application ID). Null leaves ownership to the
backend, not necessarily the caller. Review ownership/permissions explicitly;
do not feed a future workspace-created group into the foundation. Null storage
root omits that argument. Creation manages no storage or identity.

Use the repository-root [three-module example](../modules/databricks_metastore/README.md#composition).
Its `./modules/...` sources are relative to the caller at this repository root,
not to the documentation directory, and are not published source references.
Keep existing authentication; bootstrap the account provider independently of
workspace-derived authentication, secrets and identities.

The target graph is:

```text
foundation storage/account metastore -> workspace -> workspace identities
  -> account assignment -> optional delay -> workspace metastore grants
  -> credentials / external locations / catalogs
```

The workspace depends on foundation-only creation, never assignment, grants or
the old combined module. Pass the numeric Databricks workspace ID (integer
1..9223372036854775807), not the Azure ARM resource ID, to assignment. Pass its
`ready_metastore_id` to grants; creation's `metastore_id` alone bypasses the
assignment barrier. Assignment's other outputs (`assignment_id`, `metastore_id`,
`workspace_id`) do not wait for the optional delay.

The delay is bounded waiting, not polling or a readiness guarantee; zero skips
it. Changing only a positive duration does not rerun a completed sleep.
Provider retries or separately verified readiness handling may still be needed.
The grants module's `metastore_id` output orders downstream work after grants;
it likewise proves no API/authorization convergence.

Grants use `list(object({ principal = string, privileges = set(string) }))`:
one unique, nonblank principal per entry and nonempty sets of nonblank
privileges. Merge every required mapping into one authoritative manager per
metastore, not one per attached workspace. Default `grants = []` clears existing
grants; removals and destruction revoke access. Include the managing identity's
required grants. This is distinct from transferring metastore ownership.

## Preconditions and review gates

1. Record current module/provider versions, actual resource addresses and state
   ownership under the normal authorized change procedure. Back up state and
   coordinate locking before any approved state change. This task executes no
   state, cloud, plan, apply, destroy or import operations.
2. Establish whether the account/region already has a metastore and whether the
   workspace is assigned. The `test/databricks` fixture destruction is
   **user-reported**, not cloud-verified, and proves neither account metastore
   deletion nor absence of a regional metastore.
3. Review the intended owner, storage, complete grants, permissions and deletion
   protection. Previously `force_destroy` was hardcoded true; now false is the
   default. Enabling it risks deleting a nonempty metastore and is a separate
   destructive decision, not a migration workaround.
4. Review the shared split and obtain publication approval plus an approved
   published reference before Azure integration. Only isolated validation may
   use local copies; do not rewrite production pins to local sibling paths.
5. Review a migration-specific plan after approved configuration/state changes.
   Stop on unexpected replacement, deletion, ownership changes or revoked access.
   Static validation is not live readiness or safe-migration proof.

Creating the foundation before a workspace does **not** establish a universal
automatic Unity Catalog onboarding opt-out. No verified Terraform setting here
suppresses all automatic assignment/onboarding, and no provisioning settings
are changed by this split.

## Retained and relocated state addresses

These illustrative addresses assume the old creation caller remains
`module.metastore` and the new callers use the names in the README. Real nested
paths, `count` and `for_each` keys must be taken from the actual configuration
and state. Never move the entire old module into the assignment module.

| Existing address | New address / disposition |
| --- | --- |
| `module.metastore.databricks_metastore.this` | Same address if the complete creation module path is retained; no state move needed |
| `module.metastore.databricks_metastore_assignment.this` | `module.metastore_assignment.databricks_metastore_assignment.this` |
| `module.metastore.databricks_grants.this` | `module.metastore_grants.databricks_grants.this` |
| `module.metastore.time_sleep.assignment_propogation` | Removed local timer; replacement barrier is `module.metastore_assignment.time_sleep.propagation[0]` only when delay > 0 |

Creation's resource label and `metastore_id` output are retained. This does not
preserve an address if a wrapper or any parent module path is renamed; that
requires its own reviewed resource-level move. A stable address also does not
guarantee a no-change plan when owner/storage/other arguments change.

The following are **optional planned examples only**, not commands executed by
this task. Use only after confirming both old and new addresses refer to the
same remote assignment/grants, the destination is unoccupied, provider mappings
are correct and the migration is authorized:

```sh
terraform state mv 'module.metastore.databricks_metastore_assignment.this' 'module.metastore_assignment.databricks_metastore_assignment.this'
terraform state mv 'module.metastore.databricks_grants.this' 'module.metastore_grants.databricks_grants.this'
```

Do not apply configuration removal first: destroying the old assignment/grants
can unassign the workspace or revoke access. Preserve them through reviewed
resource moves (or separately reviewed declarative moves), then inspect the
resulting plan. Do not move a metastore or principal merely to eliminate an
error, and never blindly `state rm` a managed metastore or group.

The old timer's name really is misspelled `assignment_propogation`. It has no
remote cloud object. Normal planned removal of that old `time_sleep` state
resource has no remote effects; a fresh new barrier may wait again. Do not
assume the old timer maps directly to the new counted timer with triggers, and
do not confuse this timer with similarly named external-location or Azure
grant-propagation timers outside this shared-module split.

## Existing or automatically created assignments

For provider 1.138.0, account assignment creation uses **POST**, not PUT. The
provider has no verified implicit adoption branch and repeated same-assignment
POST idempotency is not established. Do not treat an automatically assigned
workspace as a safe fresh creation.

- If the assignment is already managed at the old address, review a state move,
  not an import of the same object into a second address.
- If inspection establishes an existing matching assignment outside state,
  stop for a **separately reviewed import**. Verify actual workspace/metastore
  IDs, provider version and import contract first. The documented 1.138.0
  assignment import identifier is `workspace_id|metastore_id`; this guide does
  not execute an import or embed automatic adoption.
- If the actual assignment differs, resolve the ownership/change decision
  explicitly; do not silently overwrite, delete or adopt it.
- A discovered shared metastore is not automatically an owned foundation.
  Do not auto-import it or enable `force_destroy` to bypass conflicts. Adopting
  any metastore requires an independent ownership and lifecycle review.

## Evidence and limitations

Provider contract evidence was checked against Databricks provider 1.138.0:
[metastore](https://github.com/databricks/terraform-provider-databricks/blob/v1.138.0/docs/resources/metastore.md),
[assignment source](https://github.com/databricks/terraform-provider-databricks/blob/v1.138.0/catalog/resource_metastore_assignment.go)
and the [account assignment API](https://docs.databricks.com/api/azure/account/accountmetastoreassignments/create).
The [time sleep contract](https://registry.terraform.io/providers/hashicorp/time/latest/docs/resources/sleep)
describes a delay, not Databricks health verification. Recheck contracts for the
consumer's approved provider versions. Shared logical separation alone does not
prove Azure's final dependency graph, published availability, live account
absence, repeat-POST behavior or successful onboarding suppression.
