locals {
  azure_subscription = "development"
}

variable "azure_subscription_id" {
  type    = string
  default = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
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
  default = "3ddcc102-7f43-4885-ae16-c872c65584c6"
}

variable "azure_notm_group_oid" {
  type    = string
  default = "1687acb2-20d2-4b0c-96c0-9be788cdcab9"
}

variable "azure_csra_group_oid" {
  type    = string
  default = "531fa282-da48-4ba5-9373-e1d1a1836f00"
}

variable "azure_digital_hub_group_oid" {
  type    = string
  default = "5914163b-54b9-4ad1-b04c-debf07720233"
}

variable "azure_nomis_api_group_oid" {
  type    = string
  default = "c9028ae9-59e2-46c5-8ea6-2eba74271d86"
}

variable "azure_aap_group_oid" {
  type    = string
  default = "e48a63e8-9b32-427a-8cd5-12b5faacb50a"
}

variable "azure_licences_group_oid" {
  type    = string
  default = "deb8884e-c108-4aa5-995c-14609c0cc7d2"
}


locals {
  azure_offloc_group_oid   = "f7185b7d-392e-43a0-9fc7-06b8639766ed"
  azure_fixngo_jenkins_oid = "23d9e503-7bb8-4f5a-8080-72329bd434cf"
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

locals {
  studio_ip    = "217.33.148.210"
  moj_vpn_ip   = "81.134.202.29"
  dev_forti_ip = "51.141.45.69"
}
