variable "app-name" {
  type    = string
  default = "iis-prod"
}

variable "tags" {
  type = map

  default = {
    Service     = "IIS"
    Environment = "Prod"
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

resource "random_id" "sql-mwhitfield-password" {
  byte_length = 16
}

resource "random_id" "sql-iisuser-password" {
  byte_length = 16
}
resource "random_id" "sql-sgandalwar-password" {
  byte_length = 16
}
resource "azurerm_storage_account" "storage" {
  name                     = "${replace(var.app-name, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  account_tier             = "Standard"
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
  soft_delete_enabled = true

  sku_name = "standard"

  tenant_id = var.azure_tenant_id

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_webops_group_oid
    certificate_permissions = ["Get", "List", "Update", "Create", "Import", "Recover", "Backup", "Restore", "ManageContacts", "ManageIssuers", "GetIssuers", "ListIssuers"]
    key_permissions         = []
    secret_permissions      = var.azure_secret_permissions_all
  }

  access_policy {
    tenant_id          = var.azure_tenant_id
    object_id          = var.azure_app_service_oid
    key_permissions    = []
    secret_permissions = ["set"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    certificate_permissions = ["Get", "List", "Import"]
    key_permissions         = []
    secret_permissions      = ["Set", "Get"]
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
  space_gb              = "250"
  collation             = "Latin1_General_CS_AS"
  tags                  = var.tags

  db_users = {
    iisuser    = random_id.sql-iisuser-password.b64_url
    mwhitfield = random_id.sql-mwhitfield-password.b64_url
    sgandalwar = random_id.sql-sgandalwar-password.b64_url
  }

  setup_queries = [
    "IF SCHEMA_ID('HPA') IS NULL EXEC sp_executesql \"CREATE SCHEMA HPA\"",
    "GRANT SELECT ON SCHEMA::HPA TO iisuser",
    "GRANT SELECT ON SCHEMA::IIS TO iisuser",
    "GRANT SELECT, INSERT, DELETE ON SCHEMA::NON_IIS TO iisuser",
    "ALTER ROLE db_datareader ADD MEMBER sgandalwar",
    "ALTER ROLE db_datawriter ADD MEMBER sgandalwar",
    "ALTER ROLE db_ddladmin ADD MEMBER sgandalwar",
    "GRANT SHOWPLAN to sgandalwar",
  ]
}

resource "azurerm_sql_firewall_rule" "app-access" {
  count               = length(split(",", azurerm_app_service.app.outbound_ip_addresses))
  name                = "Application IP ${count.index}"
  resource_group_name = azurerm_resource_group.group.name
  server_name         = module.sql.server_name
  start_ip_address    = element(split(",", azurerm_app_service.app.outbound_ip_addresses), count.index)
  end_ip_address      = element(split(",", azurerm_app_service.app.outbound_ip_addresses), count.index)
}

resource "azurerm_app_service_plan" "plan" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name

  kind = "app"

  sku {
    tier     = "Standard"
    size     = "S1"
    capacity = "2"
  }

  tags = {
    Service     = var.tags["Service"]
    Environment = var.tags["Environment"]
  }
}

resource "azurerm_app_service" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.plan.id

  app_settings = {
    DB_USER                            = "iisuser"
    DB_PASS                            = random_id.sql-iisuser-password.b64_url
    DB_SERVER                          = module.sql.db_server
    DB_NAME                            = module.sql.db_name
    SESSION_SECRET                     = random_id.session-secret.b64_url
    CLIENT_ID                          = data.external.vault.result.client_id
    CLIENT_SECRET                      = data.external.vault.result.client_secret
    TOKEN_HOST                         = "https://signon.service.justice.gov.uk"
    ADMINISTRATORS                     = data.external.vault.result.administrators
    APPINSIGHTS_INSTRUMENTATIONKEY     = azurerm_application_insights.app.instrumentation_key
    WEBSITE_HTTPLOGGING_RETENTION_DAYS = "180"
    WEBSITE_NODE_DEFAULT_VERSION       = "6.9.1"
  }

  site_config {
    always_on   = true
    scm_type    = "LocalGit"
    php_version = "5.6"

    default_documents = ["Default.htm", "Default.html", "Default.asp", "index.htm", "index.html", "iisstart.htm", "default.aspx", "index.php", "hostingstart.html"]

    ip_restriction {
      ip_address = "${var.ips["office"]}/32"
    }

    ip_restriction {
      ip_address = "${var.ips["quantum"]}/32"
    }

    ip_restriction {
      ip_address = "${var.ips["quantum_alt"]}/32"
    }

    ip_restriction {
      ip_address = "35.177.252.195/32"
    }

    ip_restriction {
      ip_address = "${var.ips["mojvpn"]}/32"
    }

    ip_restriction {
      ip_address = "157.203.176.138/31"
    }

    ip_restriction {
      ip_address = "157.203.176.140/32"
    }

    ip_restriction {
      ip_address = "157.203.177.190/31"
    }

    ip_restriction {
      ip_address = "157.203.177.192/32"
    }

    ip_restriction {
      ip_address = "62.25.109.201/32"
    }

    ip_restriction {
      ip_address = "62.25.109.203/32"
    }

    ip_restriction {
      ip_address = "212.137.36.233/32"
    }

    ip_restriction {
      ip_address = "212.137.36.234/32"
    }

    ip_restriction {
      ip_address = "195.59.75.0/24"
    }

    ip_restriction {
      ip_address = "194.33.192.0/25"
    }

    ip_restriction {
      ip_address = "194.33.193.0/25"
    }

    ip_restriction {
      ip_address = "194.33.196.0/25"
    }

    ip_restriction {
      ip_address = "194.33.197.0/25"
    }

    #dxc_webproxy1
    ip_restriction {
      ip_address = "195.92.38.20/32"
    }

    #dxc_webproxy2
    ip_restriction {
      ip_address = "195.92.38.21/32"
    }

    #dxc_webproxy3
    ip_restriction {
      ip_address = "195.92.38.22/32"
    }

    #dxc_webproxy4
    ip_restriction {
      ip_address = "195.92.38.23/32"
    }
  }
}

resource "azurerm_application_insights" "app" {
  name                = var.app-name
  location            = "northeurope" // Not in UK yet
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
  retention_in_days   = 90
  sampling_percentage = 0

  tags = {
    Service     = var.tags["Service"]
    Environment = var.tags["Environment"]
  }
}

/*
built in feature now - can remove once tf resource added
https://www.terraform.io/docs/providers/azurerm/d/key_vault_secret.html
*/

data "external" "vault" {
  program = ["python3", "../../tools/keyvault-data-cli-auth.py"]

  query = {
    vault = azurerm_key_vault.vault.name

    client_id     = "signon-client-id"
    client_secret = "signon-client-secret"

    administrators = "administrators"

    dashboard_token     = "dashboard-token"
    appinsights_api_key = "appinsights-api-key"
  }
}

resource "azurerm_template_deployment" "webapp-ssl" {
  name                = "webapp-ssl"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-ssl.template.json")

  parameters = {
    name             = azurerm_app_service.app.name
    hostname         = "${azurerm_dns_cname_record.cname.name}.${azurerm_dns_cname_record.cname.zone_name}"
    keyVaultId       = azurerm_key_vault.vault.id
    keyVaultCertName = "hpaDOTserviceDOThmppsDOTdsdDOTio"
    service          = var.tags["Service"]
    environment      = var.tags["Environment"]
  }

  depends_on = [azurerm_app_service.app]
}

module "slackhook" {
  source             = "../../shared/modules/slackhook"
  app_name           = azurerm_app_service.app.name
  azure_subscription = "production"
  channels           = ["shef_changes", "hpa"]
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "hpa"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "${var.app-name}.azurewebsites.net"
  tags                = var.tags
}

resource "azurerm_template_deployment" "stats-exposer" {
  name                = "stats-exposer-app"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice.template.json")

  parameters = {
    name        = "${var.app-name}-stats-exposer"
    service     = var.tags["Service"]
    environment = var.tags["Environment"]
    workers     = "2"
    sku_name    = "S1"
    sku_tier    = "Standard"
  }
}

resource "azurerm_template_deployment" "stats-expos-erconfig" {
  name                = "stats-exposer-config"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../stats-webapp-config.template.json")

  parameters = {
    name                        = azurerm_template_deployment.stats-exposer.parameters.name
    DASHBOARD_TARGET            = "https://iis-monitoring.herokuapp.com"
    DASHBOARD_TOKEN             = data.external.vault.result.dashboard_token
    APPINSIGHTS_APP_ID          = "5595f5b0-cfb0-4af0-ac47-f46f8abc2c1e"
    APPINSIGHTS_API_KEY         = data.external.vault.result.appinsights_api_key
    APPINSIGHTS_UPDATE_INTERVAL = 15
    APPINSIGHTS_QUERY_week      = "traces | where timestamp > ago(7d) | where message == 'AUDIT' | summarize count() by tostring(customDimensions.key)"
    APPINSIGHTS_QUERY_today     = "traces | where timestamp > startofday(now()) | where message == 'AUDIT' | summarize count() by tostring(customDimensions.key)"
  }

  depends_on = [azurerm_template_deployment.stats-exposer]
}

resource "azurerm_template_deployment" "stats-exposer-github" {
  name                = "stats-exposer-github"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_body       = file("../../shared/appservice-scm.template.json")

  parameters = {
    name    = azurerm_template_deployment.stats-exposer.parameters.name
    repoURL = "https://github.com/ministryofjustice/ai-stats-exposer.git"
    branch  = "master"
  }

  depends_on = [azurerm_template_deployment.stats-exposer]
}

resource "github_repository_webhook" "stats-exposer-deploy" {
  repository = "ai-stats-exposer"

  configuration {
    url          = "${azurerm_template_deployment.stats-exposer-github.outputs["deployTrigger"]}?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}

output "advice" {
  value = [
    "Don't forget to set up the SQL instance user/schemas manually.",
    "Application Insights continuous export must also be done manually",
  ]
}
