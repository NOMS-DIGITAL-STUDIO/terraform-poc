locals {
  azure_subscription = "production"
}

variable "azure_subscription_id" {
  type    = "string"
  default = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
}

variable "azure_tenant_id" {
  type    = "string"
  default = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}

variable "azure_app_service_oid" {
  type    = "string"
  default = "5b2509b1-64bd-4117-b839-9b0c2b02e02c"
}

variable "azure_webops_group_oid" {
  type    = "string"
  default = "98dc3307-f515-4717-b3c1-7174413e20b0"
}

variable "azure_jenkins_sp_oid" {
  type    = "string"
  default = "880790d6-77d8-4f9b-9df7-f60097801381"
}

locals {
  azure_empty_group_oid    = "2e86efbd-c741-452f-8922-5c9d91120bff"
  azure_fixngo_jenkins_oid = "d2f0d768-d785-4e6f-98d6-fab105032ff1"
}

variable "azure_secret_permissions_all" {
  type = "list"

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

variable "azure_certificate_permissions_all" {
  type = "list"

  default = [
    "create",
      "delete",
      "deleteissuers",
      "get",
      "getissuers",
      "import",
      "list",
      "listissuers",
      "managecontacts",
      "manageissuers",
      "setissuers",
      "update",
  ]
}

locals {
  dns_zone_name = "service.hmpps.dsd.io"
  dns_zone_rg   = "webops-prod"
  studio_ip      = "217.33.148.210"
  moj_vpn_ip      = "81.134.202.29"
  prod_forti_ip  = "51.141.53.111"
}
