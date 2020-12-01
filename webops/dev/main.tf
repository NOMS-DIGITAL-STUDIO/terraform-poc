locals {
  env-name = "devtest"
}

variable "tags" {
  type = map

  default = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_resource_group" "group" {
  name     = "webops"
  location = "ukwest"
  tags     = var.tags
}

resource "azurerm_key_vault" "vault" {
  name                = "webops-dev"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  soft_delete_enabled = true
  sku_name            = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_webops_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    object_id          = var.slackhook_app_oid
    tenant_id          = var.azure_tenant_id
    key_permissions    = []
    secret_permissions = ["get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}
