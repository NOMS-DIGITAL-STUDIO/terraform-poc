
resource "azurerm_key_vault" "ssl_az_justice_gov_uk" {
  name                     = "certs-az-justice-gov-uk"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  sku_name                 = "standard"
  purge_protection_enabled = true

  tenant_id = var.azure_tenant_id

  #hmpps-preprod-ukwest-appgw-managed-identity
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "36f8d8db-4cb1-4d94-9d0e-6f8031d9782f"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "daa6e2f7-ebdd-4552-9d62-6b27e3a98732"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "e7f4553b-8d24-413f-8381-0b8aa7759912"
    key_permissions         = var.azure_key_permissions_all
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_webops_group_oid
    key_permissions         = ["Get", "List", "Update", "Create", "Import"]
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  #hmpps-prod-uksouth-appgw-managed-identity
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "8a65aed7-e34f-4988-8b90-2a2fcc41e355"
    key_permissions         = ["Get", "List", "Update", "Create", "Import"]
    secret_permissions      = var.azure_secret_permissions_all
    certificate_permissions = var.azure_certificate_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_app_service_oid
    key_permissions         = []
    secret_permissions      = ["Get"]
    certificate_permissions = ["Get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    key_permissions         = []
    secret_permissions      = ["Get", "Set"]
    certificate_permissions = ["Get", "List", "Import"]
  }

  #Microsoft.Azure.CertificateRegistration
  #app id: f3c21649-0979-4721-ac85-b0216b2cf413

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "5657dd88-834a-4007-8a2a-88397be8c27a"
    key_permissions         = []
    secret_permissions      = ["Get", "Set", "Delete"]
    certificate_permissions = []
  }


  # digital-studio-webops-jenkins-prod
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = "a3415938-d0a1-4cfe-b312-edf87c251a69"
    key_permissions         = []
    secret_permissions      = ["Get"]
    certificate_permissions = ["Import", "Get", "List"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "ssl_az_justice_gov_uk_vault_diagnostics" {
  name               = "certs-az-justice-gov-uk-logging"
  target_resource_id = azurerm_key_vault.ssl_az_justice_gov_uk.id
  log_analytics_workspace_id = "/subscriptions/1d95dcda-65b2-4273-81df-eb979c6b547b/resourceGroups/noms-prod-loganalytics/providers/Microsoft.OperationalInsights/workspaces/noms-prod1"

  log {
    category = "AuditEvent"
    enabled = true

    retention_policy {
      days    = 0
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"
    enabled = false

    retention_policy {
      days    = 0
      enabled = false
    }
  }
}
