variable "app" {
  type = string
}

variable "env" {
  type = string
}
locals {
  name    = "${var.app}-${var.env}"
  storage = "${var.app}${var.env}storage"

  github_deploy_branch = "deploy-to-${var.env}"
}
#When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
variable "certificate_kv_secret_id" {
  type        = string
  default     = null
  description = "Used to bind a certificate to the app"
}
variable "key_vault_secrets" {
  type = list(string)
  default = []
}

variable "certificate_name" {
  type = string
}
variable "scm_type" {
  type = string
  default = null
}
variable "tags" {
  type = map
}

variable "app_service_kind" {
  type = string
  default = "app"
}

variable "https_only" {
  type    = bool
  default = null
}

variable "http2_enabled" {
  type    = bool
  default = false
}

variable "scm_use_main_ip_restriction" {
  type    = bool
  default = null
}
variable "sc_branch" {
  type    = string
  default = null
}
variable "repo_url" {
  type    = string
  default = null
}
variable "app_service_plan_size" {
  type    = string
  default = "B1"
}
variable "ip_restriction_addresses" {
  type = list(string)
  default = []
}

variable "sampling_percentage" {
  type        = string
  description = "Fixed rate samping for app insights for reduing volume of telemetry"
}
variable "custom_hostname" {
  type        = string
  description = "custom hostname for the app service"
}
variable "has_database" {
  type        = bool
  description = "If the app service creates a sql server and DB with the app service"
}

variable "signon_hostname" {
  type        = string
  default = null
  description = "If the app uses a token host in the app config which redirects to a signon page"
}

variable "app_settings" {
  type = map
  default = null
}
variable "dso_certificates_oid" {
  #app id: 11efc5bf-0012-4a0f-ae6b-d21f1c43f251 display name: dso-certificates
  type    = string
  default = "a3415938-d0a1-4cfe-b312-edf87c251a69"
}
variable "azure_jenkins_sp_oid" {
  type        = string
  description = ""
}

variable "azure_tenant_id" {
  type    = string
  default = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}

variable "azure_app_service_oid" {
  type    = string
  default = "5b2509b1-64bd-4117-b839-9b0c2b02e02c"
}

variable "azure_webops_group_oid" {
  type    = string
  default = "98dc3307-f515-4717-b3c1-7174413e20b0"
}


variable "azure_certificate_permissions_all" {
  type = list

  default = [
    "Get",
    "List",
    "Update",
    "Create",
    "Import",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "ManageContacts",
    "ManageIssuers",
    "GetIssuers",
    "ListIssuers",
    "SetIssuers",
    "DeleteIssuers",
    "Purge",
  ]
}
variable "log_containers" {
  type    = list
  default = []
}

variable "azure_secret_permissions_all" {
  type = list

  default = [
    "backup",
    "delete",
    "get",
    "list",
    "purge",
    "recover",
    "restore",
    "set",
  ]
}

variable "default_documents" {
  type        = list(string)
  default     = null
  description = "default documents for the app site config"
}
