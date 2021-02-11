variable "app-name" {
  type    = string
  default = "iis-prod"
}

variable "tags" {
  type = map

  default = {
    application      = "HPA"
    environment_name = "prod"
    service          = "Misc"
  }
}

locals {
  key_vault_secrets = ["signon-client-id", "signon-client-secret", "administrators"]
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
    secret_permissions = ["Get"]
  }

  access_policy {
    tenant_id               = var.azure_tenant_id
    object_id               = var.azure_jenkins_sp_oid
    certificate_permissions = ["Get", "List", "Import"]
    key_permissions         = []
    secret_permissions      = ["Set", "Get"]
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
    capacity = "1"
  }

  tags = var.tags
}

resource "azurerm_app_service" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  app_service_plan_id = azurerm_app_service_plan.plan.id
  tags                = var.tags
  app_settings = {
    DB_USER                        = "iisuser"
    DB_PASS                        = random_id.sql-iisuser-password.b64_url
    DB_SERVER                      = module.sql.db_server
    DB_NAME                        = module.sql.db_name
    SESSION_SECRET                 = random_id.session-secret.b64_url
    CLIENT_ID                      = data.azurerm_key_vault_secret.kv_secrets["signon-client-id"].value
    CLIENT_SECRET                  = data.azurerm_key_vault_secret.kv_secrets["signon-client-secret"].value
    TOKEN_HOST                     = "https://signon.service.justice.gov.uk"
    ADMINISTRATORS                 = data.azurerm_key_vault_secret.kv_secrets["administrators"].value
    APPINSIGHTS_INSTRUMENTATIONKEY = azurerm_application_insights.app.instrumentation_key
    WEBSITE_NODE_DEFAULT_VERSION   = "6.9.1"
  }


  site_config {
    always_on                   = true
    scm_type                    = "LocalGit"
    php_version                 = "5.6"
    scm_use_main_ip_restriction = true

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

    #pttp access
    ip_restriction {
      ip_address = "51.149.250.0/24"
    }
    ip_restriction {
      ip_address = "${var.ips["studiohosting-live"]}/32"
    }
  }
}


resource "azurerm_application_insights" "app" {
  name                = var.app-name
  location            = azurerm_resource_group.group.location
  resource_group_name = azurerm_resource_group.group.name
  application_type    = "web"
  retention_in_days   = 90
  sampling_percentage = 50

  tags = var.tags
}

resource "azurerm_app_service_certificate" "webapp-ssl" {
  name                = "iis-prod-iis-prod-CERThpaDOTserviceDOThmppsDOTdsdDOTio"
  resource_group_name = azurerm_resource_group.group.name
  location            = azurerm_resource_group.group.location
  tags                = var.tags
  #When you need to re-create add the key vault secret key id in, comment after so it doesn't get in the way of the plan or you'll need to main after every cert refresh
  #key_vault_secret_id = "https://iis-prod.vault.azure.net/secrets/iis-prod-iis-prod-CERThpaDOTserviceDOThmppsDOTdsdDOTio"
}


resource "azurerm_app_service_certificate_binding" "binding" {
  hostname_binding_id = "/subscriptions/a5ddf257-3b21-4ba9-a28c-ab30f751b383/resourceGroups/iis-prod/providers/Microsoft.Web/sites/iis-prod/hostNameBindings/hpa.service.hmpps.dsd.io"
  certificate_id      = "/subscriptions/a5ddf257-3b21-4ba9-a28c-ab30f751b383/resourceGroups/iis-prod/providers/Microsoft.Web/certificates/iis-prod-iis-prod-CERThpaDOTserviceDOThmppsDOTdsdDOTio"
  ssl_state           = "SniEnabled"
}

resource "azurerm_app_service_custom_hostname_binding" "custom-binding" {
  hostname            = "hpa.service.hmpps.dsd.io"
  app_service_name    = azurerm_app_service.app.name
  resource_group_name = azurerm_resource_group.group.name
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "hpa"
  zone_name           = "service.hmpps.dsd.io"
  resource_group_name = "webops-prod"
  ttl                 = "300"
  record              = "${var.app-name}.azurewebsites.net"
  tags                = var.tags
}



output "advice" {
  value = [
    "Don't forget to set up the SQL instance user/schemas manually.",
    "Application Insights continuous export must also be done manually",
  ]
}
