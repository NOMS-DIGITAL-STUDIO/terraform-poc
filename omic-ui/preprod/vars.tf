variable "app-name" {
  type    = "string"
  default = "omic-preprod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "omic-ui"
    Environment = "PreProd"
  }
}

# App settings
locals {
  api_endpoint_url    = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io/elite2api/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api-preprod.service.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm-preprod.service.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-preprod"
  google_analytics_id = ""
}

# Azure config
locals {
  azurerm_resource_group = "omic-ui-preprod"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}
