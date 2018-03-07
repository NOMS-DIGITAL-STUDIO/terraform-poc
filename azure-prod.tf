variable "azure_subscription_id" {
    type = "string"
    default = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
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

variable "azure_jenkins_sp_oid" {
    type = "string"
    default = "880790d6-77d8-4f9b-9df7-f60097801381"
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
