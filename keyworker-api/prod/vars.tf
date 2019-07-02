variable "app-name" {
  type    = "string"
  default = "keyworker-api-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "keyworker-api"
    Environment = "Prod"
  }
}

# Instance and Deployment settings
locals {
  instances = "3"
  mininstances = "2"
  instance_size = "t2.medium"
  backup_retention_period = "30"
}

locals {
  api_base_endpoint      = "https://gateway.prod.nomis-api.service.hmpps.dsd.io"
  elite2_uri_root        = "${local.api_base_endpoint}/elite2api"
  auth_uri_root          = "${local.api_base_endpoint}/auth"
  omic_clientid          = "omicadmin"
  server_timeout         = "180000"
  azurerm_resource_group = "keyworker-api-prod"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
    "${var.ips["omic-ui-prod"]}/32",
    "${var.ips["notm-prod-1"]}/32",
    "${var.ips["notm-prod-2"]}/32",
    "${var.ips["cloudplatform-live1-1"]}/32",
    "${var.ips["cloudplatform-live1-2"]}/32",
    "${var.ips["cloudplatform-live1-3"]}/32",
  ]
}
