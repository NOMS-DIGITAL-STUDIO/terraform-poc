variable "app-name" {
  type    = "string"
  default = "omic-prod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "omic-ui"
    Environment = "Prod"
  }
}

# Instance and Deployment settings
locals {
  instances = "2"
  mininstances = "1"
}

# App settings
locals {
  api_base_endpoint   = "https://gateway.nomis-api.service.justice.gov.uk"
  api_endpoint_url    = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url   = "${local.api_base_endpoint}/auth/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api.service.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm.service.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-prod"
  google_analytics_id = "UA-106741063-2"
  maintain_roles_enabled = false
}

# Azure config
locals {
  azurerm_resource_group = "omic-ui-prod"
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
