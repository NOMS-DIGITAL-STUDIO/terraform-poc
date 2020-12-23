variable "app-name" {
  type    = string
  default = "iis-preprod"
}
variable "tags" {
  type = map
  default = {
    Service     = "IIS"
    Environment = "Preprod"
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
resource "random_id" "sql-iisuser-password" {
  byte_length = 16
}
resource "random_id" "sql-atodd-password" {
  byte_length = 16
}
resource "random_id" "sql-mwhitfield-password" {
  byte_length = 16
}
resource "random_id" "sql-sgandalwar-password" {
  byte_length = 16
}

resource "azurerm_storage_account" "storage" {
  name                      = "${replace(var.app-name, "-", "")}storage"
  resource_group_name       = azurerm_resource_group.group.name
  location                  = azurerm_resource_group.group.location
  account_tier              = "Standard"
  account_replication_type  = "RAGRS"
  account_kind              = "Storage"
  tags                      = var.tags
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
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    certificate_permissions = ["get", "list", "import"]
    key_permissions         = []
    secret_permissions      = ["set", "get"]
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
      label = "NOMS Studio office"
      start = var.ips["office"]
      end   = var.ips["office"]
    },
    {
      label = "MOJ Digital"
      start = var.ips["mojvpn"]
      end   = var.ips["mojvpn"]
    },
  ]
  audit_storage_account = azurerm_storage_account.storage.name
  edition               = "Standard"
  scale                 = "S3"
  space_gb              = 250
  collation             = "Latin1_General_CS_AS"
  tags                  = var.tags

  db_users = {
    iisuser    = random_id.sql-iisuser-password.b64_url
    atodd      = random_id.sql-atodd-password.b64_url
    mwhitfield = random_id.sql-mwhitfield-password.b64_url
    sgandalwar = random_id.sql-sgandalwar-password.b64_url
  }

  setup_queries = [
    "IF SCHEMA_ID('HPA') IS NULL EXEC sp_executesql \"CREATE SCHEMA HPA\"",
    "GRANT SELECT ON SCHEMA::HPA TO iisuser",
    "GRANT SELECT ON SCHEMA::IIS TO iisuser",
    "GRANT SELECT, INSERT, DELETE ON SCHEMA::NON_IIS TO iisuser",
    "ALTER ROLE db_datareader ADD MEMBER atodd",
    "ALTER ROLE db_datawriter ADD MEMBER atodd",
    "ALTER ROLE db_ddladmin ADD MEMBER atodd",
    "GRANT SHOWPLAN to atodd",
    "ALTER ROLE db_datareader ADD MEMBER mwhitfield",
    "ALTER ROLE db_datawriter ADD MEMBER mwhitfield",
    "ALTER ROLE db_ddladmin ADD MEMBER mwhitfield",
    "GRANT SHOWPLAN to mwhitfield",
    "ALTER ROLE db_datareader ADD MEMBER sgandalwar",
    "ALTER ROLE db_datawriter ADD MEMBER sgandalwar",
    "ALTER ROLE db_ddladmin ADD MEMBER sgandalwar",
    "GRANT SHOWPLAN to sgandalwar",
  ]
}

resource "azurerm_sql_firewall_rule" "app-access" {
  count               = length(split(",", azurerm_template_deployment.webapp.outputs["ips"]))
  name                = "Application IP ${count.index}"
  resource_group_name = azurerm_resource_group.group.name
  server_name         = module.sql.server_name
  start_ip_address    = element(split(",", azurerm_template_deployment.webapp.outputs["ips"]), count.index)
  end_ip_address      = element(split(",", azurerm_template_deployment.webapp.outputs["ips"]), count.index)
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
    sku_name    = "S2"
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
    storageSAS = data.external.sas-url.result["url"]
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
    name = azurerm_template_deployment.webapp.parameters.name
    ip1  = var.ips["office"]
    ip2  = var.ips["quantum"]
    ip3  = var.ips["quantum_alt"]
    ip4  = var.ips["studiohosting-live"]
    
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
    DB_PASS                        = random_id.sql-iisuser-password.b64_url
    DB_SERVER                      = module.sql.db_server
    DB_NAME                        = module.sql.db_name
    SESSION_SECRET                 = random_id.session-secret.b64_url
    CLIENT_ID                      = data.external.vault.result["client_id"]
    CLIENT_SECRET                  = data.external.vault.result["client_secret"]
    TOKEN_HOST                     = "https://signon.service.justice.gov.uk"
    ADMINISTRATORS                 = data.external.vault.result["administrators"]
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
    keyVaultCertName = "hpa-preprodDOTserviceDOThmppsDOTdsdDOTio"
    service          = var.tags["Service"]
    environment      = var.tags["Environment"]
  }

  depends_on = [azurerm_template_deployment.webapp]
}

resource "azurerm_template_deployment" "webapp-github" {
  name                = "webapp-github"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-scm.template.json")

  parameters = {
    name    = var.app-name
    repoURL = "https://github.com/ministryofjustice/iis.git"
    branch  = "deploy-to-preprod"
  }

  depends_on = [azurerm_template_deployment.webapp]
}


resource "github_repository_webhook" "webapp-deploy" {
  repository = "iis"

  configuration {
    url          = "${azurerm_template_deployment.webapp-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
}

module "slackhook" {
  source             = "../../shared/modules/slackhook"
  app_name           = azurerm_template_deployment.webapp.parameters.name
  azure_subscription = "production"
  channels           = ["hpa"]
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "hpa-preprod"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "${var.app-name}.azurewebsites.net"
  tags                = var.tags
}

output "advice" {
  value = [
    "Don't forget to set up the SQL instance user/schemas manually.",
    "Application Insights continuous export must also be done manually"
  ]
}
