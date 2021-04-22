
resource "azurerm_key_vault" "webops_jenkins" {
  name                     = "webops-jenkins-prod"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  sku_name                 = "standard"
  purge_protection_enabled = true
  tenant_id                = var.azure_tenant_id

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.github_actions_prod_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_webops_group_oid
    key_permissions    = []
    secret_permissions = ["Get", "List", "Set", "Delete", "Recover", "Backup", "Restore"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_jenkins_sp_oid
    key_permissions    = []
    secret_permissions = ["Set", "Get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = "11efc5bf-0012-4a0f-ae6b-d21f1c43f251" # dso-certificates
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = "c666e4d6-6452-42b9-ab84-0df839c4aa65" # ansible-monorepo-prod
    key_permissions    = []
    secret_permissions = ["get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}
