variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "Prod"
  }
}

# App settings
locals {
  api_endpoint_url    = "https://gateway.nomis-api.service.justice.gov.uk/elite2api/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api.service.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm.service.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-prod"
  google_analytics_id = "UA-106741063-2"
}

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-prod"
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