
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
locals {
  key_vault_secrets = ["signon-client-id", "signon-client-secret", "administrators"]
}

data "azurerm_key_vault_secret" "kv_secrets" {
  for_each     = toset(local.key_vault_secrets)
  name         = each.value
  key_vault_id = module.app_service.vault_id
}
module "app_service" {

  source                = "../../shared/modules/azure-app-service"
  app                   = var.app
  env                   = var.env
  sa_name               = "${replace(local.name, "-", "")}storage"
  certificate_name      = var.certificate_name
  app_service_plan_size = "S1"
  scm_type              = "LocalGit"
  key_vault_secrets     = ["signon-client-id", "signon-client-secret", "administrators"]
  azure_jenkins_sp_oid  = var.azure_jenkins_sp_oid
  log_containers        = var.log_containers
  ip_restriction_addresses = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["quantum_alt"]}/32",
    "35.177.252.195/32",
    "${var.ips["mojvpn"]}/32",
    "157.203.176.138/31",
    "157.203.176.140/32",
    "157.203.177.190/31",
    "157.203.177.192/32",
    "62.25.109.201/32",
    "62.25.109.203/32",
    "212.137.36.233/32",
    "212.137.36.234/32",
    "195.59.75.0/24",
    "194.33.192.0/25",
    "194.33.193.0/25",
    "194.33.196.0/25",
    "194.33.197.0/25",
    "195.92.38.20/32", #dxc_webproxy1
    "195.92.38.21/32", #dxc_webproxy2
    "195.92.38.22/32", #dxc_webproxy3
    "195.92.38.23/32", #dxc_webproxy4
    "51.149.250.0/24", #pttp access
    "${var.ips["studiohosting-live"]}/32"
  ]
  use_32_bit_worker_process   = false
  always_on                   = true
  signon_hostname             = var.signon_hostname
  sampling_percentage         = var.sampling_percentage
  scm_use_main_ip_restriction = var.scm_use_main_ip_restriction
  custom_hostname             = var.custom_hostname
  has_storage                 = var.has_storage
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
  tags = var.tags
  app_settings = {
    DB_PASS        = random_id.sql-iisuser-password.b64_url
    SESSION_SECRET = random_id.session-secret.b64_url
    ADMINISTRATORS = data.azurerm_key_vault_secret.kv_secrets["administrators"].value
    CLIENT_ID      = data.azurerm_key_vault_secret.kv_secrets["signon-client-id"].value
    CLIENT_SECRET  = data.azurerm_key_vault_secret.kv_secrets["signon-client-secret"].value
    DB_SERVER      = "${local.name}.database.windows.net"
    DB_USER        = "${var.app}user"
    DB_NAME        = local.name
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
  count               = length(module.app_service.app_service_outbound_ips)
  name                = "Application IP ${count.index}"
  resource_group_name = local.name
  server_name         = module.sql.server_name
  start_ip_address    = element(module.app_service.app_service_outbound_ips, count.index)
  end_ip_address      = element(module.app_service.app_service_outbound_ips, count.index)
}


resource "azurerm_dns_cname_record" "cname" {
  name                = "hpa"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "${local.name}.azurewebsites.net"
  tags                = var.tags
}

output "advice" {
  value = [
    "Don't forget to set up the SQL instance user/schemas manually.",
    "Application Insights continuous export must also be done manually",
  ]
}
