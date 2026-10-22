terraform {
  required_providers {
    databricks = {
      source = "databricks/databricks"
      configuration_aliases = [ databricks.workspace ]
    }
  }
}

## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS GIT CREDENTIAL RESOURCE
##
## This resource configures Git credentials in Databricks.
## 
## Parameters:
## - `git_provider`: The Git provider. Example: "GitHub"
## - `git_username`: The username for Git authentication. Example: "myusername"
## - `personal_access_token`: The personal access token for Git authentication. Example: "mytoken"
## - `force`: Whether to force update Git credentials. Example: true
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_git_credential" "this" {
  provider              = databricks.workspace

  git_provider          = var.git_provider
  git_username          = var.git_username
  personal_access_token = var.git_pat
  force                 = true
}


## ---------------------------------------------------------------------------------------------------------------------
## DATABRICKS REPOSITORY RESOURCE
##
## This resource configures a Git repository in Databricks.
## 
## Parameters:
## - `git_provider`: The Git provider. Example: "GitHub"
## - `url`: The URL of the Git repository. Example: "https://github.com/myorg/myrepo.git"
## - `branch`: The Git branch. Example: "main"
## ---------------------------------------------------------------------------------------------------------------------
resource "databricks_repo" "this" {
  provider     = databricks.workspace

  git_provider = var.git_provider
  url          = var.git_url
  branch       = var.git_branch
}
