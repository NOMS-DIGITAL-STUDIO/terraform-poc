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
  instances = "3"
  mininstances = "2"
  instance_size = "t2.medium"
}

# App settings
locals {
  api_base_endpoint   = "https://gateway.prod.nomis-api.service.hmpps.dsd.io"
  api_endpoint_url    = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url   = "${local.api_base_endpoint}/auth/"
  api_client_id       = "elite2apiclient"
  keyworker_api_url   = "https://keyworker-api.service.hmpps.dsd.io/"
  nn_endpoint_url     = "https://notm.service.hmpps.dsd.io/"
  omic_ui_url         = "https://omic.service.hmpps.dsd.io/"
  prison_staff_hub_ui_url = "https://prisonstaffhub.service.hmpps.dsd.io/"
  hmpps_cookie_name   = "hmpps-session-prod"
  google_analytics_id = "UA-106741063-2"
  google_tag_manager_id = "GTM-TKDSFNC"
  maintain_roles_enabled = "true"
  keyworker_profile_stats_enabled = "true"
  keyworker_dashboard_stats_enabled = "true"
  remote_auth_strategy = "true"
  session_timeout_mins        = "60"
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
    "${var.ips["digitalprisons1"]}/32",
    "${var.ips["digitalprisons2"]}/32",
    "${var.ips["j5-phones-1"]}/32",
    "${var.ips["j5-phones-2"]}/32",
    "${var.ips["sodexo-northumberland"]}/32",
    "${var.ips["thameside-private-prison"]}/32",
    "${var.ips["ark-nps-hmcts-ttp1"]}/24",
    "${var.ips["ark-nps-hmcts-ttp2"]}/25",
    "${var.ips["ark-nps-hmcts-ttp3"]}/25",
    "${var.ips["ark-nps-hmcts-ttp4"]}/25",
    "${var.ips["ark-nps-hmcts-ttp5"]}/25",
  ]
}
