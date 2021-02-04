locals {
  azure_subscription = "production"
}

variable "azure_subscription_id" {
  type    = string
  default = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
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

variable "azure_jenkins_sp_oid" {
  type    = string
  default = "880790d6-77d8-4f9b-9df7-f60097801381"
}

variable "devops_prod_oid" {
  #app id: 70edcce8-9cd1-475f-997b-96e6e2e2448d display name: AzureDevOpsProd
  type    = string
  default = "2b59743a-aae5-4961-ae3e-57ebd0d0889c"
}

variable "github_actions_prod_oid" {
  #app id: f98c8e0b-b98b-4bb1-98fd-bdfde40787ce display name: GitHubActionsProd
  type    = string
  default = "bc67b5d4-0df5-4791-9747-b8f7d1bf16a3"
}

variable "dso_certificates_oid" {
  #app id: 11efc5bf-0012-4a0f-ae6b-d21f1c43f251 display name: dso-certificates
  type    = string
  default = "a3415938-d0a1-4cfe-b312-edf87c251a69"
}

locals {
  azure_empty_group_oid    = "2e86efbd-c741-452f-8922-5c9d91120bff"
  azure_fixngo_jenkins_oid = "d2f0d768-d785-4e6f-98d6-fab105032ff1"
}

variable "azure_secret_permissions_all" {
  type = list

  default = [
    "Get",
    "List",
    "Set",
    "Delete",
    "Recover",
    "Backup",
    "Restore",
    "Purge",
  ]
}

variable "azure_key_permissions_all" {
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
    "Decrypt",
    "Encrypt",
    "UnwrapKey",
    "WrapKey",
    "Verify",
    "Sign",
    "Purge",
  ]
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

locals {
  dns_zone_name = "service.hmpps.dsd.io"
  dns_zone_rg   = "webops-prod"
  studio_ip     = "217.33.148.210"
  moj_vpn_ip    = "81.134.202.29"
  prod_forti_ip = "51.141.53.111"
}
