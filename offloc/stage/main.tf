
module "app_service" {
  source                       = "../../shared/modules/azure-app-service"
  app                          = var.app
  env                          = var.env
  certificate_name             = var.certificate_name
  app_service_kind             = "Windows"
  sc_branch                    = var.sc_branch
  repo_url                     = var.repo_url
  https_only                   = true
  client_affinity_enabled      = true
  sa_name                      = "${replace(local.name, "-", "")}app"
  has_storage                  = var.has_storage
  azure_jenkins_sp_oid         = var.azure_jenkins_sp_oid
  azure_repo_app_principal_oid = var.azure_repo_app_principal_oid
  sampling_percentage          = var.sampling_percentage
  custom_hostname              = var.custom_hostname
  app_settings = {
    "AZURE_STORAGE_ACCOUNT_NAME"    = "offlocstageapp"
    "AZURE_STORAGE_CONTAINER_NAME"  = "cde"
    "AZURE_STORAGE_RESOURCE_GROUP"  = "offloc-stage"
    "AZURE_STORAGE_SUBSCRIPTION_ID" = "c27cfedb-f5e9-45e6-9642-0fad1a5c94e7"
    "KEY_VAULT_URL"                 = "https://offloc-stage-users.vault.azure.net/"
    "NODE_ENV"                      = "production"
    "SESSION_SECRET"                = random_id.session.id
    "WEBSITE_NODE_DEFAULT_VERSION"  = "14.15.1"
    "WEBSITE_TIME_ZONE"             = "GMT Standard Time"

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
  tags         = var.tags
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
    object_id          = local.azure_offloc_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = module.app_service.app_identity
    key_permissions    = []
    secret_permissions = ["get", "set", "list", "delete"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = false
  tags                            = var.tags
}

resource "azurerm_monitor_diagnostic_setting" "app-vault-diagnostics" {
  name                       = "${local.name}-users-logging"
  target_resource_id         = azurerm_key_vault.app.id
  log_analytics_workspace_id = var.workspace_id

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
