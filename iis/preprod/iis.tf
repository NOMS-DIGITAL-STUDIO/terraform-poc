variable "app-name" {
  type    = string
  default = "iis-preprod"
}

locals {
  ip_addresses      = ["217.33.148.210/32", "62.25.109.197/32", "212.137.36.230/32", "192.0.2.4/32", "192.0.2.5/32", "192.0.2.6/32", "192.0.2.7/32", "192.0.2.8/32", "192.0.2.9/32", "192.0.2.10/32", "192.0.2.11/32", "192.0.2.12/32", "192.0.2.13/32", "192.0.2.14/32", "192.0.2.15/32", "20.49.225.111/32"]
  key_vault_secrets = ["signon-client-id", "signon-client-secret", "administrators"]
}

data "azurerm_key_vault_secret" "kv_secrets" {
  for_each     = toset(local.key_vault_secrets)
  name         = each.value
  key_vault_id = module.app_service.vault_id
}
variable "tags" {
  type = map
  default = {
    application      = "HPA"
    environment_name = "preprod"
    service          = "Misc"
  }
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

module "app_service" {
  source                   = "../../shared/modules/azure-app-service"
  app                      = var.app
  env                      = var.env
  sa_name = "${replace(local.name, "-", "")}storage"
  certificate_name         = var.certificate_name
  https_only               = true
  sc_branch = var.sc_branch
  repo_url = var.repo_url
  key_vault_secrets = ["signon-client-id", "signon-client-secret", "administrators"]
  log_containers = var.log_containers
  azure_jenkins_sp_oid     = var.azure_jenkins_sp_oid
  ip_restriction_addresses = var.ip_restriction_addresses
  signon_hostname          = var.signon_hostname
  sampling_percentage      = var.sampling_percentage
  scm_use_main_ip_restriction = var.scm_use_main_ip_restriction
  custom_hostname          = var.custom_hostname
  has_storage             = var.has_storage
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
  tags = {
    "application"      = "HPA"
    "environment_name" = "preprod"
    "service"          = "Misc"
  }
  app_settings = {
    DB_PASS = random_id.sql-iisuser-password.b64_url
  SESSION_SECRET = random_id.session-secret.b64_url
  ADMINISTRATORS                 = data.azurerm_key_vault_secret.kv_secrets["administrators"].value
  CLIENT_ID                      = data.azurerm_key_vault_secret.kv_secrets["signon-client-id"].value
  CLIENT_SECRET                  = data.azurerm_key_vault_secret.kv_secrets["signon-client-secret"].value
  DB_SERVER  = "${local.name}.database.windows.net"
  DB_USER    = "${var.app}user"
  DB_NAME    = local.name
  TOKEN_HOST = var.signon_hostname }
}

module "sql" {
  source              = "../../shared/modules/azure-sql"
  name                = local.name
  resource_group      = local.name
  location            = module.app_service.rg_location
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
  audit_storage_account = "${replace(local.name, "-", "")}storage"
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
  count               = length(module.app_service.app_service_outbound_ips)
  name                = "Application IP ${count.index}"
  resource_group_name = local.name
  server_name         = local.name
  start_ip_address    = module.app_service.app_service_outbound_ips[count.index]
  end_ip_address      = module.app_service.app_service_outbound_ips[count.index]
  depends_on          = [module.app_service.webapp]
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
