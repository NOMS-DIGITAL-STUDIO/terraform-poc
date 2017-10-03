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

// These AD ObjectIDs were found via `az ad sp list`
variable "azure_glenm_tf_oid" {
    type = "string"
    default = "3763b95f-5a74-4aa9-a596-2960bf7fb799"
}
variable "azure_robl_tf_oid" {
    type = "string"
    default = "ec0c3ab3-0a6e-4260-87c3-93935fe29b3e"
}
provider "azurerm" {
    # NOMS Digital Studio Dev & Test Environments
    subscription_id = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    # client_id = "..." use ARM_CLIENT_ID env var
    # client_secret = "..." use ARM_CLIENT_SECRET env var
    tenant_id = "${var.azure_tenant_id}"
}
