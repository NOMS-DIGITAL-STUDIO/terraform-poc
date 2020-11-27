variable "app-name" {
  type    = string
  default = "iis-stage"
}
variable "tags" {
  type = map
  default = {
    Service     = "IIS"
    Environment = "Stage"
  }
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
  enable_https_traffic_only        = false
  account_tier             = "Standard"
  account_kind             = "Storage"
  account_replication_type = "RAGRS"

  tags = var.tags
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

  enabled_for_deployment          = false
  enabled_for_disk_encryption     = false
  enabled_for_template_deployment = true
  soft_delete_enabled             = true

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
  tags                  = var.tags
}

resource "azurerm_template_deployment" "webapp" {
  name                = "webapp"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice.template.json")
  parameters = {
    name        = var.app-name
    service     = var.tags["Service"]
    environment = var.tags["Environment"]
    workers     = "2"
    sku_name    = "S1"
    sku_tier    = "Standard"
  }
}

data "external" "sas-url" {
  program = ["python3", "../../tools/container-sas-url-cli-auth.py"]
  query = {
    subscription_id = var.azure_subscription_id
    tenant_id       = var.azure_tenant_id
    resource_group  = azurerm_resource_group.group.name
    storage_account = azurerm_storage_account.storage.name
    container       = "web-logs"
    permissions     = "rwdl"
    start_date      = "2017-05-15T00:00:00Z"
    end_date        = "2217-05-15T00:00:00Z"
  }
}

resource "azurerm_template_deployment" "webapp-weblogs" {
  name                = "webapp-weblogs"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-weblogs.template.json")

  parameters = {
    name       = azurerm_template_deployment.webapp.parameters.name
    storageSAS = data.external.sas-url.result.url
  }

  depends_on = [azurerm_template_deployment.webapp]
}

resource "azurerm_template_deployment" "insights" {
  name                = var.app-name
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/insights.template.json")
  parameters = {
    name         = azurerm_template_deployment.webapp.parameters.name
    location     = "northeurope" // Not in UK yet
    service      = var.tags["Service"]
    environment  = var.tags["Environment"]
    appServiceId = azurerm_template_deployment.webapp.outputs["resourceId"]
  }
}

resource "azurerm_template_deployment" "webapp-whitelist" {
  name                = "webapp-whitelist"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-whitelist.template.json")

  parameters = {
    name    = azurerm_template_deployment.webapp.parameters.name
    ip1     = "0.0.0.0"
    subnet1 = "0.0.0.0"
  }

  depends_on = [azurerm_template_deployment.webapp]
}

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]
  query = {
    vault = azurerm_key_vault.vault.name

    client_id     = "signon-client-id"
    client_secret = "signon-client-secret"

    administrators = "administrators"
  }
}

resource "azurerm_template_deployment" "webapp-config" {
  name                = "webapp-config"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../webapp-config.template.json")

  parameters = {
    name                           = azurerm_template_deployment.webapp.parameters.name
    DB_USER                        = "iisuser"
    DB_PASS                        = random_id.sql-user-password.b64_url
    DB_SERVER                      = module.sql.db_server
    DB_NAME                        = module.sql.db_name
    SESSION_SECRET                 = random_id.session-secret.b64_url
    CLIENT_ID                      = data.external.vault.result.client_id
    CLIENT_SECRET                  = data.external.vault.result.client_secret
    TOKEN_HOST                     = "https://www.signon.dsd.io"
    ADMINISTRATORS                 = data.external.vault.result.administrators
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_template_deployment.insights.outputs["instrumentationKey"]
  }

  depends_on = [azurerm_template_deployment.webapp]
}

resource "azurerm_template_deployment" "webapp-ssl" {
  name                = "webapp-ssl"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-ssl.template.json")

  parameters = {
    name             = azurerm_template_deployment.webapp.parameters.name
    hostname         = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
    keyVaultId       = azurerm_key_vault.vault.id
    keyVaultCertName = "hpa-stageDOThmppsDOTdsdDOTio"
    service          = var.tags["Service"]
    environment      = var.tags["Environment"]
  }

  depends_on = [azurerm_template_deployment.webapp]
}

module "slackhook" {
  source   = "../../shared/modules/slackhook"
  app_name = azurerm_template_deployment.webapp.parameters.name
  channels = ["hpa"]
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "hpa-stage"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops-shared-dns-devtest"
  ttl                 = "300"
  record              = "${var.app-name}.azurewebsites.net"
  tags                = var.tags
}

output "advice" {
  value = "Don't forget to set up the SQL instance user/schemas manually."
}
