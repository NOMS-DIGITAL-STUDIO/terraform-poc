variable "azure_subscription_id" {
    type = "string"
    default = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
}
variable "azure_tenant_id" {
    type = "string"
    default = "747381f4-e81f-4a43-bf68-ced6a1e14edf"
}
variable "azure_app_service_oid" {
  type = "string"
  default = "5b2509b1-64bd-4117-b839-9b0c2b02e02c"
}
variable "azure_webops_group_oid" {
    type = "string"
    default = "98dc3307-f515-4717-b3c1-7174413e20b0"
}
variable "azure_notm_group_oid" {
	type = "string"
	default = "1687acb2-20d2-4b0c-96c0-9be788cdcab9"
}
variable "azure_csra_group_oid" {
	type = "string"
	default = "531fa282-da48-4ba5-9373-e1d1a1836f00"
}
variable "azure_digital_hub_group_oid" {
	type = "string"
	default = "5914163b-54b9-4ad1-b04c-debf07720233"
}
variable "azure_nomis_api_group_oid" {
	type = "string"
	default = "c9028ae9-59e2-46c5-8ea6-2eba74271d86"
}
variable "azure_iis_group_oid" {
	type = "string"
	default = "cce161c1-f0fb-499f-bbef-cf7788cc3928"
}
variable "azure_nomis_aap_group_oid" {
	type = "string"
	default = "e48a63e8-9b32-427a-8cd5-12b5faacb50a"
}


// These AD ObjectIDs were found via `az ad sp list`
variable "azure_glenm_tf_oid" {
    type = "string"
    default = "3763b95f-5a74-4aa9-a596-2960bf7fb799"
}
variable "azure_robl_tf_oid" {
    type = "string"
    default = "ec0c3ab3-0a6e-4260-87c3-93935fe29b3e"
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
