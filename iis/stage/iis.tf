variable "app-name" {
  type    = string
  default = "iis-stage"
}

locals {
  ip_addresses      = ["0.0.0.0/0", "192.0.2.2/32", "192.0.2.3/32", "192.0.2.4/32", "192.0.2.5/32", "192.0.2.6/32", "192.0.2.7/32", "192.0.2.8/32", "192.0.2.9/32", "192.0.2.10/32", "192.0.2.11/32", "192.0.2.12/32", "192.0.2.13/32", "192.0.2.14/32", "192.0.2.15/32"]
  key_vault_secrets = ["signon-client-id", "signon-client-secret", "administrators"]
}

variable "tags" {
  type = map
  default = {
    application      = "HPA"
    environment_name = "devtest"
    service          = "Misc"
  }
}
data "azurerm_key_vault_secret" "kv_secrets" {
  for_each     = toset(local.key_vault_secrets)
  name         = each.value
  key_vault_id = azurerm_key_vault.vault.id
}

resource "azurerm_resource_group" "group" {
  name     = var.app-name
  location = "ukwest"
  tags     = var.tags
}

resource "random_id" "session-secret" {
  byte_length = 20
}
resource "random_id" "sql-user-password" {
  byte_length = 16
}

resource "azurerm_storage_account" "storage" {
  name                     = "${replace(var.app-name, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  account_tier             = "Standard"
  account_kind             = "Storage"
  account_replication_type = "RAGRS"
  tags                     = var.tags
}

variable "log-containers" {
  type    = list
  default = ["app-logs", "web-logs", "db-logs"]
}
resource "azurerm_storage_container" "logs" {
  count                 = length(var.log-containers)
  name                  = var.log-containers[count.index]
  storage_account_name  = azurerm_storage_account.storage.name
  container_access_type = "private"
}

resource "azurerm_key_vault" "vault" {
  name                = var.app-name
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  sku_name            = "standard"
  tenant_id           = var.azure_tenant_id

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_webops_group_oid
    certificate_permissions = var.azure_certificate_permissions_all
    key_permissions         = []
    secret_permissions      = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_iis_group_oid
    key_permissions    = []
    secret_permissions = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    certificate_permissions = ["Get", "List", "Import"]
    key_permissions         = []
    secret_permissions      = ["Set", "Get"]
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.dso_certificates_oid
    certificate_permissions = ["Get", "List", "Import"]
    key_permissions         = []
    secret_permissions      = ["get"]
  }

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true

  tags = var.tags
}

module "sql" {
  source              = "../../shared/modules/azure-sql"
  name                = var.app-name
  resource_group      = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  administrator_login = "iis"
  firewall_rules = [
    {
      label = "Open to the world"
      start = "0.0.0.0"
      end   = "255.255.255.255"
    },
  ]
  audit_storage_account = azurerm_storage_account.storage.name
  edition               = "Basic"
  scale                 = "Basic"
  collation             = "SQL_Latin1_General_CP1_CI_AS"
  tags = {
    application      = "HPA"
    environment_name = "devtest"
    service          = "Misc"
  }
}

resource "azurerm_app_service_plan" "webapp-plan" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  kind                = "app"
  tags                = var.tags
  sku {
    tier = "Standard"
    size = "S1"
  }
}

resource "azurerm_app_service" "webapp" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.webapp-plan.id
  tags                = var.tags
  https_only          = true
  client_cert_enabled = false


  site_config {
    dotnet_framework_version = "v4.0"
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
    always_on                 = true
    php_version               = "5.6"
    use_32_bit_worker_process = true

    dynamic "ip_restriction" {
      for_each = local.ip_addresses
      content {
        ip_address = ip_restriction.value
      }
    }
  }

  #Couldn't get logs to work as the sas token kept completing the apply, but reverting to file system logs
  #Instead needs to be enabled in the portal under app service logs -> "Web Service Logging" -> Storage -> "iisstagestorage" -> "web-logs"
  #  logs {
  #    http_logs {
  #      azure_blob_storage {
  #
  #        retention_in_days = 180
  #        sas_url           = data.azurerm_storage_account_sas.sas_token.sas
  #      }
  #    }
  #  }
  source_control {
    branch             = "azure"
    manual_integration = false
    repo_url           = "https://github.com/ministryofjustice/iis"
    rollback_enabled   = false
    use_mercurial      = false
  }

  app_settings = {
    ADMINISTRATORS                 = data.azurerm_key_vault_secret.kv_secrets["administrators"].value
    CLIENT_ID                      = data.azurerm_key_vault_secret.kv_secrets["signon-client-id"].value
    CLIENT_SECRET                  = data.azurerm_key_vault_secret.kv_secrets["signon-client-secret"].value
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    "DB_NAME"                      = var.app-name
    "DB_PASS"                      = random_id.sql-user-password.b64_url
    "DB_SERVER"                    = "${var.app-name}.database.windows.net"
    "DB_USER"                      = "iisuser"
    "SESSION_SECRET"               = random_id.session-secret.b64_url
    "TOKEN_HOST"                   = "https://www.signon.dsd.io"
    "WEBSITE_NODE_DEFAULT_VERSION" = "6.9.1"
  }
}

resource "azurerm_application_insights" "insights" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
  retention_in_days   = 90
  sampling_percentage = 100
  tags                = var.tags
}

resource "azurerm_app_service_certificate" "webapp-ssl" {
  name                = "iis-stage-iis-stage-CERThpa-stageDOThmppsDOTdsdDOTio"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  tags                = var.tags
  #When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
  #key_vault_secret_id = "https://iis-stage.vault.azure.net/secrets/CERThpa-stageDOThmppsDOTdsdDOTio/5e38400ed7a84020b284d6dacb1f2a0"
}


resource "azurerm_app_service_certificate_binding" "binding" {
  hostname_binding_id = "/subscriptions/c27cfedb-f5e9-45e6-9642-0fad1a5c94e7/resourceGroups/iis-stage/providers/Microsoft.Web/sites/iis-stage/hostNameBindings/hpa-stage.hmpps.dsd.io"
  certificate_id      = "/subscriptions/c27cfedb-f5e9-45e6-9642-0fad1a5c94e7/resourceGroups/iis-stage/providers/Microsoft.Web/certificates/iis-stage-iis-stage-CERThpa-stageDOThmppsDOTdsdDOTio"
  ssl_state           = "SniEnabled"
}

resource "azurerm_resource_group_template_deployment" "site-extension" {
  name                = "webapp-extension"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_content    = file("../../shared/appservice-extension.template.json")

  parameters_content = jsonencode({
    name = { value = azurerm_app_service.webapp.name }
  })
  depends_on = [azurerm_app_service.webapp]
}
resource "azurerm_app_service_custom_hostname_binding" "custom-binding" {
  hostname            = "hpa-stage.hmpps.dsd.io"
  app_service_name    = azurerm_app_service.webapp.name
  resource_group_name = azurerm_resource_group.group.name
}

output "advice" {
  value = "Don't forget to set up the SQL instance user/schemas manually."
}
