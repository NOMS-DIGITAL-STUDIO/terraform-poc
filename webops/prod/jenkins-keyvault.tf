
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
    object_id          = "a3415938-d0a1-4cfe-b312-edf87c251a69" # dso-certificates
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = "4a65e4b7-189c-4d87-980a-050b9969009d" # ansible-monorepo-prod
    key_permissions    = []
    secret_permissions = ["get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "webops_jenkins_vault_diagnostics" {
  name                       = "webops-jenkins-prod-logging"
  target_resource_id         = azurerm_key_vault.webops_jenkins.id
  log_analytics_workspace_id = "/subscriptions/1d95dcda-65b2-4273-81df-eb979c6b547b/resourceGroups/noms-prod-loganalytics/providers/Microsoft.OperationalInsights/workspaces/noms-prod1"

  log {
    category = "AuditEvent"
    enabled  = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled  = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
