variable "name" {
  type = string
}
variable "resource_group" {
  type = string
}
variable "location" {
  type = string
}
variable "administrator_login" {
  type = string
}
variable "firewall_rules" {
  type = list(any)
  default = [
    # for example
    # {
    #     label = "value"
    #     start = "0.0.0.0"
    #     end = "0.0.0.0"
    # },
  ]
}
variable "audit_storage_account" {
  type = string
}
variable "edition" {
  type    = string
  default = "Basic"
}
variable "scale" {
  type    = string
  default = ""
  # eg "S3"
}
variable "space_gb" {
  type    = string
  default = "2"
}
variable "collation" {
  type    = string
  default = "SQL_Latin1_General_CP1_CI_AS"
}
variable "tags" {
  type = map(any)
  # default {
  #    Service = "xxx"
  #    Environment = "xxx"
  # }
}
variable "db_users" {
  type    = map(any)
  default = {}
  # {
  #     username = "password"
  #     username2 = "password2"
  #     ...
  # }
}
variable "setup_queries" {
  type = list(any)
  default = [
    # list of string SQL commands to run
  ]
}

resource "random_id" "sql-admin-password" {
  byte_length = 32
}

resource "azurerm_sql_server" "sql" {
  name                         = var.name
  resource_group_name          = var.resource_group
  location                     = var.location
  version                      = "12.0"
  administrator_login          = var.administrator_login
  administrator_login_password = random_id.sql-admin-password.b64_url
  tags                         = var.tags
  lifecycle {
    prevent_destroy = true
  }
}

resource "azurerm_sql_firewall_rule" "firewall" {
  count               = length(var.firewall_rules)
  name                = lookup(var.firewall_rules[count.index], "label")
  resource_group_name = var.resource_group
  server_name         = azurerm_sql_server.sql.name
  start_ip_address    = lookup(var.firewall_rules[count.index], "start")
  end_ip_address      = lookup(var.firewall_rules[count.index], "end")
}

resource "azurerm_template_deployment" "sql-audit" {
  name                = "sql-audit"
  resource_group_name = var.resource_group
  deployment_mode     = "Incremental"
  template_body       = file("${path.module}/../../azure-sql-audit.template.json")
  parameters = {
    serverName         = azurerm_sql_server.sql.name
    storageAccountName = var.audit_storage_account
  }
}

resource "azurerm_sql_database" "db" {
  name                             = var.name
  resource_group_name              = var.resource_group
  location                         = var.location
  server_name                      = azurerm_sql_server.sql.name
  edition                          = var.edition
  requested_service_objective_name = var.scale
  max_size_bytes                   = var.space_gb * 1024 * 1024 * 1024
  collation                        = var.collation
  tags                             = var.tags
  # lifecycle {
  #     prevent_destroy = true
  # }
}

resource "null_resource" "user-setup" {
  depends_on = [azurerm_sql_database.db]

  triggers = {
    queries = jsonencode(var.db_users)
  }

  provisioner "local-exec" {
    # Base64 to handle quoting issues
    command = <<CMD
${path.module}/db-setup.py \
    --server '${azurerm_sql_server.sql.fully_qualified_domain_name}' \
    --username '${var.administrator_login}' \
    --password '${random_id.sql-admin-password.b64_url}' \
    --database '${azurerm_sql_database.db.name}' \
    --users '${base64encode(jsonencode(var.db_users))}' \
CMD
  }
}

resource "null_resource" "db-setup" {
  depends_on = [azurerm_sql_database.db, null_resource.user-setup]

  triggers = {
    queries = jsonencode(var.setup_queries)
  }

  provisioner "local-exec" {
    # Base64 to handle quoting issues
    command = <<CMD
${path.module}/db-setup.py \
    --server '${azurerm_sql_server.sql.fully_qualified_domain_name}' \
    --username '${var.administrator_login}' \
    --password '${random_id.sql-admin-password.b64_url}' \
    --database '${azurerm_sql_database.db.name}' \
    --queries '${base64encode(jsonencode(var.setup_queries))}' \
CMD
  }
}

resource "azurerm_template_deployment" "sql-tde" {
  name                = "sql-tde"
  resource_group_name = var.resource_group
  deployment_mode     = "Incremental"
  template_body       = file("${path.module}/../../azure-sql-tde.template.json")
  parameters = {
    serverName   = azurerm_sql_server.sql.name
    databaseName = azurerm_sql_database.db.name
    service      = var.tags["service"]
    environment  = var.tags["environment_name"]
  }
}

output "server_name" {
  value = azurerm_sql_server.sql.name
}
output "db_server" {
  value = azurerm_sql_server.sql.fully_qualified_domain_name
}
output "db_name" {
  value = azurerm_sql_database.db.name
}
