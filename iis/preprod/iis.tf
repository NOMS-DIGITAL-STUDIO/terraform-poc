variable "app-name" {
  type    = string
  default = "iis-preprod"
}

locals {
  ip_addresses      = ["217.33.148.210/32", "62.25.109.197/32", "212.137.36.230/32", "192.0.2.4/32", "192.0.2.5/32", "192.0.2.6/32", "192.0.2.7/32", "192.0.2.8/32", "192.0.2.9/32", "192.0.2.10/32", "192.0.2.11/32", "192.0.2.12/32", "192.0.2.13/32", "192.0.2.14/32", "192.0.2.15/32", "20.49.225.111/32"]
  key_vault_secrets = ["signon-client-id", "signon-client-secret", "administrators"]
}

variable "tags" {
  type = map
  default = {
    application      = "HPA"
    environment_name = "preprod"
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
  name                     = "${replace(var.app-name, "-", "")}storage"
  resource_group_name      = azurerm_resource_group.group.name
  location                 = azurerm_resource_group.group.location
  account_tier             = "Standard"
  account_replication_type = "RAGRS"
  account_kind             = "Storage"
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
  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.dso_certificates_oid
    certificate_permissions = ["get", "list", "import"]
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

# you may need to do a target apply on the app service first if building from scratch
resource "azurerm_sql_firewall_rule" "app-access" {
  count               = length(azurerm_app_service.webapp.outbound_ip_address_list)
  name                = "Application IP ${count.index}"
  resource_group_name = azurerm_resource_group.group.name
  server_name         = module.sql.server_name
  start_ip_address    = azurerm_app_service.webapp.outbound_ip_address_list[count.index]
  end_ip_address      = azurerm_app_service.webapp.outbound_ip_address_list[count.index]
  depends_on          = [azurerm_app_service.webapp]
}

resource "azurerm_app_service_plan" "webapp-plan" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  kind                = "app"
  tags                = var.tags
  sku {
    tier = "Basic"
    size = "B1"
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
    always_on   = true
    php_version = "5.6"

    # even though in state it is external git with a source control block we can't have both in terraform code.
    #    scm_type                  = "ExternalGit"
    scm_use_main_ip_restriction = true
    use_32_bit_worker_process   = true

    dynamic "ip_restriction" {
      for_each = local.ip_addresses
      content {
        ip_address = ip_restriction.value
      }
    }
  }
  source_control {
    branch             = "deploy-to-preprod"
    manual_integration = true
    repo_url           = "https://github.com/ministryofjustice/iis.git"
    rollback_enabled   = false
    use_mercurial      = false
  }

  #Couldn't get logs to work as the sas token kept completing the apply, but reverting to file system logs
  #Instead needs to be enabled in the portal under app service logs -> "Web Service Logging" -> Storage -> "iispreprodstorage" -> "web-logs"
  #  logs {
  #  http_logs {
  #      azure_blob_storage {
  #
  #        retention_in_days = 180
  #        sas_url           = data.azurerm_storage_account_sas.sas_token.sas
  #      }
  #    }
  #  }

  app_settings = {
    ADMINISTRATORS                 = data.azurerm_key_vault_secret.kv_secrets["administrators"].value
    CLIENT_ID                      = data.azurerm_key_vault_secret.kv_secrets["signon-client-id"].value
    CLIENT_SECRET                  = data.azurerm_key_vault_secret.kv_secrets["signon-client-secret"].value
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.insights.instrumentation_key
    DB_NAME                        = var.app-name
    DB_PASS                        = random_id.sql-iisuser-password.b64_url
    DB_SERVER                      = "${var.app-name}.database.windows.net"
    DB_USER                        = "iisuser"
    SESSION_SECRET                 = random_id.session-secret.b64_url
    TOKEN_HOST                     = "https://signon.service.justice.gov.uk"
    WEBSITE_NODE_DEFAULT_VERSION   = "6.9.1"
  }
}

resource "azurerm_application_insights" "insights" {
  name                = var.app-name
  location            = "northeurope" #zurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
  retention_in_days   = 90
  sampling_percentage = 0
  tags                = var.tags
}

resource "azurerm_app_service_certificate" "webapp-ssl" {
  name                = "iis-preprod-iis-preprod-CERThpa-preprodDOTserviceDOThmppsDOTdsdDOTio"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  tags                = var.tags
  #When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
  #key_vault_secret_id = "https://iis-preprod.vault.azure.net/secrets/CERThpa-preprodDOThmppsDOTdsdDOTio/5e38400ed7a84020b284d6dacb1f2a0"
}


resource "azurerm_app_service_certificate_binding" "binding" {
  hostname_binding_id = "/subscriptions/a5ddf257-3b21-4ba9-a28c-ab30f751b383/resourceGroups/iis-preprod/providers/Microsoft.Web/sites/iis-preprod/hostNameBindings/hpa-preprod.service.hmpps.dsd.io"
  certificate_id      = "/subscriptions/a5ddf257-3b21-4ba9-a28c-ab30f751b383/resourceGroups/iis-preprod/providers/Microsoft.Web/certificates/iis-preprod-iis-preprod-CERThpa-preprodDOTserviceDOThmppsDOTdsdDOTio"
  ssl_state           = "SniEnabled"
}

resource "azurerm_app_service_custom_hostname_binding" "custom-binding" {
  hostname            = "hpa-preprod.service.hmpps.dsd.io"
  app_service_name    = azurerm_app_service.webapp.name
  resource_group_name = azurerm_resource_group.group.name
}

#no terraform resource for site extensions https://github.com/terraform-providers/terraform-provider-azurerm/issues/2328
#the extension no longer exists in the extension list so if this is ever re-built we'd need to find a new extension to do the redirect, keeping for now as it's whats live
resource "azurerm_resource_group_template_deployment" "site-extension" {
  name                = "webapp-extension"
  resource_group_name = azurerm_resource_group.group.name
  deployment_mode     = "Incremental"
  template_content    = file("../../shared/appservice-extension.template.json")

  # documentation for the new resource_group_template_deployment isn't great, it needs a json list so you write it in terraform then json encode it
  parameters_content = jsonencode({
    name = { value = azurerm_app_service.webapp.name }
  })
  depends_on = [azurerm_app_service.webapp]
}




#Don't think the deployment works currently, really this should be removed and oauth between the azure sub & github with the github scmtype should be used.
resource "github_repository_webhook" "webapp-deploy" {
  repository = "iis"

  configuration {
    # url is hardcoded to match live
    url          = "https://$iis-preprod:KvQb7vusM7WLlsrxZXEKZvJGA74jJrvTyBEWcc5wJbpK1KA0KxSbzqeSgx2z@iis-preprod.scm.azurewebsites.net/deploy?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }
  active = true

  events = ["push"]
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
