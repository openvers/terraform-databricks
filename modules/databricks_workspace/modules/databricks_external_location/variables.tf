variable "external_location_name" {
  description = "Name of the Unity Catalog external location."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.external_location_name) != "" && var.external_location_name == trimspace(var.external_location_name)
    error_message = "external_location_name must be nonblank and unpadded."
  }
}

variable "external_location_url" {
  description = "Exact cloud storage URL for the external location. No suffix is appended."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.external_location_url) != "" && var.external_location_url == trimspace(var.external_location_url)
    error_message = "external_location_url must be nonblank and unpadded."
  }
}

variable "storage_credential_name" {
  description = "Name of the existing Unity Catalog storage credential, not a cloud identity ID."
  type        = string
  nullable    = false

  validation {
    condition     = trimspace(var.storage_credential_name) != "" && var.storage_credential_name == trimspace(var.storage_credential_name)
    error_message = "storage_credential_name must be nonblank and unpadded."
  }
}

variable "read_only" {
  description = "Whether the external location is read-only."
  type        = bool
  default     = false
  nullable    = false
}

variable "force_destroy" {
  description = "Allow external location deletion regardless of dependents. False is not deletion protection."
  type        = bool
  default     = false
  nullable    = false
}

variable "external_location_grants" {
  description = "Authoritative external-location grants keyed by logical identity. Empty means revoke explicit grants within provider ownership, not leave unmanaged. Principals are user/group names or service-principal application IDs."
  type = map(object({
    principal  = string
    privileges = set(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = try(alltrue([
      for grant in values(var.external_location_grants) :
      trimspace(grant.principal) != "" && grant.principal == trimspace(grant.principal) &&
      length(grant.privileges) > 0 && alltrue([
        for privilege in grant.privileges :
        trimspace(privilege) != "" && privilege == trimspace(privilege)
      ])
    ]), false)
    error_message = "Each external-location grant must have a nonblank, unpadded principal and a nonempty set of nonblank, unpadded privileges."
  }

  validation {
    condition     = length(distinct([for grant in values(var.external_location_grants) : grant.principal])) == length(var.external_location_grants)
    error_message = "Each external-location principal must appear in only one grant entry."
  }
}

variable "catalog" {
  description = "Optional catalog to create. Presence must be plan-known; name and exact storage_root may be computed. Do not also manage this catalog in another module."
  type = object({
    name          = string
    storage_root  = string
    comment       = optional(string)
    force_destroy = optional(bool, false)
  })
  default = null

  validation {
    condition = var.catalog == null ? true : try(
      trimspace(var.catalog.name) != "" && var.catalog.name == trimspace(var.catalog.name) &&
      trimspace(var.catalog.storage_root) != "" && var.catalog.storage_root == trimspace(var.catalog.storage_root),
      false
    )
    error_message = "When catalog is configured, its name and storage_root must be nonblank and unpadded."
  }
}

variable "manage_catalog_grants" {
  description = "Whether to own authoritative catalog grants. Must be plan-known. Disabling existing management can revoke grants; it is not an ownership handoff."
  type        = bool
  default     = false
  nullable    = false

  validation {
    condition     = !var.manage_catalog_grants || var.catalog != null
    error_message = "manage_catalog_grants requires a configured catalog."
  }
}

variable "catalog_grants" {
  description = "Authoritative catalog grants keyed by logical identity, applied only when manage_catalog_grants is true. Empty means revoke explicit grants within provider ownership, not leave unmanaged."
  type = map(object({
    principal  = string
    privileges = set(string)
  }))
  default  = {}
  nullable = false

  validation {
    condition = try(alltrue([
      for grant in values(var.catalog_grants) :
      trimspace(grant.principal) != "" && grant.principal == trimspace(grant.principal) &&
      length(grant.privileges) > 0 && alltrue([
        for privilege in grant.privileges :
        trimspace(privilege) != "" && privilege == trimspace(privilege)
      ])
    ]), false)
    error_message = "Each catalog grant must have a nonblank, unpadded principal and a nonempty set of nonblank, unpadded privileges."
  }

  validation {
    condition     = length(distinct([for grant in values(var.catalog_grants) : grant.principal])) == length(var.catalog_grants)
    error_message = "Each catalog principal must appear in only one grant entry."
  }
}
