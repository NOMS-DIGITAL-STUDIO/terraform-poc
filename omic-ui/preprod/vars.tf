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

# Instance and Deployment settings
locals {
  instances = "1"
  mininstances = "1"
}

# App settings
locals {
  api_base_endpoint   = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io"
  api_endpoint_url    = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url   = "${local.api_base_endpoint}/auth/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api-preprod.service.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm-preprod.service.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-preprod"
  google_analytics_id = ""
  maintain_roles_enabled = "false"
  keyworker_profile_stats_enabled = "false"
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
