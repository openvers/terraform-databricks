# Databricks SQL-file job

Creates one cloud-neutral workspace job with 1–64 SQL-file tasks and an explicit execution identity. SQL business logic stays in caller-managed workspace files, not in this module.

## Requirements and ownership

- Terraform >= 1.5.0 and the `databricks/databricks` provider, supplied through the `databricks.workspace` alias. The module does not pin a provider version; select one supporting SQL-file tasks (see the [v1.138.0 resource contract](https://github.com/databricks/terraform-provider-databricks/blob/v1.138.0/docs/resources/job.md)).
- Supply existing SQL files in the target workspace and an existing **Pro or serverless SQL warehouse** for each task. File source is always `WORKSPACE`; Git, local filesystem paths, cloud storage URIs, notebooks, and saved SQL queries are not supported task sources.
- The caller owns file deployment, warehouse provisioning, workspace assignment, entitlements, run-as authorization, file read access, warehouse access, job ACLs, and required catalog/schema/table/external-location grants. Both deployment access and the execution identity's runtime access must be arranged independently.
- For a service-principal run-as identity, the deployer needs the `servicePrincipal/user` role on that principal. Workspace assignment alone does not grant SQL entitlements, warehouse access, or Unity Catalog permissions. SQL-file tasks execute with the configured `run_as` identity.

This module creates no warehouses, files, clusters, identities, ACLs, grants, storage, or cloud resources. Input validation checks configuration shape, not the existence, warehouse type, readability, or authorization of supplied resources.

## Example

From this repository's root, with a caller-configured workspace provider and pre-existing resources:

```hcl
variable "sql_warehouse_id" {
  type        = string
  description = "Existing Pro or serverless SQL warehouse ID."
}

variable "workspace_sql_file_path" {
  type        = string
  description = "Absolute path of an existing, readable workspace SQL file."
}

variable "run_as_application_id" {
  type        = string
  description = "Active workspace service principal application UUID, not its SCIM ID."
}

module "sql_job" {
  source = "./modules/databricks_job"

  providers = {
    databricks.workspace = databricks.workspace
  }

  name = "workspace-sql-job"
  run_as = {
    service_principal_name = var.run_as_application_id
  }
  tasks = {
    execute_sql = {
      warehouse_id  = var.sql_warehouse_id
      sql_file_path = var.workspace_sql_file_path
    }
  }
}
```

If using `databricks_service_principal`, supply its `databricks_service_principal_application_id` output to `run_as.service_principal_name`, **not** `databricks_service_principal_id` (the SCIM ID). Alternatively, set only `run_as.user_name` to an active workspace user's name; platform restrictions on assigning another user still apply.

## Inputs

All top-level inputs except `schedule` are non-nullable.

| Name | Type | Default | Contract |
| --- | --- | --- | --- |
| `name` | `string` | Required | Nonblank, no surrounding whitespace. |
| `description` | `string` | `""` | Optional job description. |
| `tags` | `map(string)` | `{}` | Caller-supplied tags; nonblank keys, non-null values. |
| `tasks` | `map(object)` | Required | 1–64 tasks, using the typed object below. |
| `parameters` | `map(string)` | `{}` | Job parameter names and default string values; separate from task SQL parameters. Names must be nonblank without surrounding whitespace; values cannot be null. Provider naming restrictions also apply. |
| `run_as` | `object({ service_principal_name = optional(string), user_name = optional(string) })` | Required | Exactly one non-null field. Service principal must be an application UUID; user name must be nonblank without whitespace. |
| `timeout_seconds` | `number` | `3600` | Nonnegative integer job timeout; `0` disables the job timeout. |
| `max_concurrent_runs` | `number` | `1` | Positive integer. |
| `schedule` | `object({ quartz_cron_expression = string, timezone_id = string })` | `null` | Omit for no schedule. Both fields must be nonblank without surrounding whitespace; the provider validates Quartz/Java timezone syntax. Always configured `PAUSED`. |

### Task object

Each map key becomes the `task_key` and must match `^[A-Za-z0-9_-]{1,100}$`.

| Field | Type | Default | Contract |
| --- | --- | --- | --- |
| `warehouse_id` | `string` | Required | Existing Pro/serverless warehouse ID, nonblank with no whitespace. |
| `sql_file_path` | `string` | Required | Absolute `WORKSPACE` file path. No empty, `.` or `..` segments, trailing slash, surrounding whitespace, or CR/LF; a `.sql` suffix is not required. |
| `depends_on` | `set(string)` | `[]` | Upstream task keys in this same map. No unknown keys, self-dependencies, or directed cycles. |
| `parameters` | `map(string)` | `{}` | SQL task parameters; nonblank names without surrounding whitespace and non-null values. |
| `timeout_seconds` | `number` | `0` | Nonnegative integer; `0` means no task timeout, but the job timeout still applies. |
| `max_retries` | `number` | `0` | Nonnegative integer; `0` means no retries. Unlimited retries (`-1`) are rejected. |
| `min_retry_interval_millis` | `number` | `0` | Nonnegative integer minimum retry interval in milliseconds. |
| `retry_on_timeout` | `bool` | `false` | Whether to retry timed-out tasks, subject to the retry limit. |

### Dependency DAG and ordering

For example, `depends_on = ["register"]` on a `views` task makes it depend on the `register` task in the same `tasks` map. Independent tasks can run concurrently; alphabetical order is not execution order.

Variable validation rejects unknown task references and direct self-dependencies. An additional resource precondition rejects indirect cycles: six repeated squarings compute reachable dependency sets for paths up to length 64, then reject any task reachable from itself. The 64-task limit makes this cycle check complete within the supported graph size. Guarded lookups let unknown references reach the explicit validation error rather than an invalid-index error. Values not known until apply defer the relevant checks until they are known.

Tasks, dependency blocks, and job parameter blocks are emitted in sorted key order for deterministic configuration. The provider models tasks as an ordered list, so adding, removing, or renaming a task can still reorder list positions and produce broader diffs.

## Scheduling and costs

The module never starts a run. An omitted schedule creates no schedule; a supplied schedule is always `PAUSED`, with no input to enable it. Pausing a schedule does not prevent separately authorized manual/API execution. Later execution or externally enabled scheduling can incur compute costs. Caller-managed warehouse creation or startup can also incur costs independently of this module and without a job run.

## Outputs

| Name | Description |
| --- | --- |
| `id` | Databricks job ID. |
| `url` | Job URL in the target workspace. |
