module "app_service" {
  source                       = "../../shared/modules/azure-app-service"
  app                          = var.app
  env                          = var.env
  certificate_name             = var.certificate_name
  app_service_kind             = "Windows"
  https_only                   = true
  client_affinity_enabled      = true
  storage_replication_type     = "GRS"
  insights_location            = "northeurope"
  sa_name                      = "${replace(local.name, "-", "")}app"
  has_storage                  = var.has_storage
  azure_jenkins_sp_oid         = var.azure_jenkins_sp_oid
  azure_repo_app_principal_oid = var.azure_repo_app_principal_oid
  sampling_percentage          = var.sampling_percentage
  custom_hostname              = var.custom_hostname
  ssl_state                    = "IpBasedEnabled"
  app_service_plan_size        = var.app_service_plan_size
  certificate_kv_secret_id     = data.azurerm_key_vault_secret.webapp_ssl_secret_id.id
  app_settings = {
    "AZURE_STORAGE_ACCOUNT_NAME"    = "offlocprodapp"
    "AZURE_STORAGE_CONTAINER_NAME"  = "cde"
    "AZURE_STORAGE_RESOURCE_GROUP"  = "offloc-prod"
    "AZURE_STORAGE_SUBSCRIPTION_ID" = "a5ddf257-3b21-4ba9-a28c-ab30f751b383"
    "KEY_VAULT_URL"                 = "https://offloc-prod-users.vault.azure.net/"
    "NODE_ENV"                      = "production"
    "SESSION_SECRET"                = random_id.session.b64_url
    "WEBSITE_TIME_ZONE"             = "GMT Standard Time"
    "WEBSITE_NODE_DEFAULT_VERSION"  = "14.15.1"

  }
  default_documents = [
    "Default.htm",
    "Default.html",
    "Default.asp",
    "index.htm",
    "index.html",
    "iisstart.htm",
    "default.aspx",
    "index.php",
    "hostingstart.html",
  ]
  workspace_id = var.workspace_id
  tags = var.tags
}


resource "random_id" "session" {
  byte_length = 40
}

resource "azurerm_role_assignment" "jenkins-write-storage" {
  scope                = module.app_service.sa_id
  role_definition_name = "Contributor"
  principal_id         = local.azure_fixngo_jenkins_oid
}

resource "azurerm_role_assignment" "app-read-storage" {
  scope                = module.app_service.sa_id
  role_definition_name = "Storage Account Key Operator Service Role"
  principal_id         = module.app_service.app_identity
}

resource "azurerm_key_vault" "app" {
  name                     = "${local.name}-users"
  resource_group_name      = local.name
  location                 = "ukwest"
  sku_name                 = "standard"
  purge_protection_enabled = true

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_webops_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {

    tenant_id          = var.azure_tenant_id
    object_id          = module.app_service.app_identity
    secret_permissions = ["get", "set", "list", "delete"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  tags                            = var.tags
}

data "azurerm_key_vault_secret" "webapp_ssl_secret_id" {
  name         = "CERTwwwDOTofflocDOTserviceDOTjusticeDOTgovDOTuk"
  key_vault_id = module.app_service.vault_id
}

resource "azurerm_monitor_diagnostic_setting" "app-vault-diagnostics" {
  name               = "${local.name}-users-logging"
  target_resource_id = azurerm_key_vault.app.id
  log_analytics_workspace_id = var.workspace_id

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
