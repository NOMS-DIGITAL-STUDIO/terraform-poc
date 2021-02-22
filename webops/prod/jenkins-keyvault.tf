
resource "azurerm_key_vault" "webops_jenkins" {
  name                = "webops-jenkins-prod"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  sku_name            = "standard"

  tenant_id = var.azure_tenant_id

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
    object_id          = var.dso_certificates_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}
