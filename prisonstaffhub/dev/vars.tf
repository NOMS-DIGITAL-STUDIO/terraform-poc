variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "Dev"
  }
}

# App settings
locals {
  api_base_endpoint            = "https://gateway.t3.nomis-api.hmpps.dsd.io"
  api_endpoint_url             = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url           = "${local.api_base_endpoint}/auth/"
  api_client_id                = "elite2apiclient"
  api_system_client_id         = "prisonstaffhubclient"
  keyworker_api_url            = "https://keyworker-api-dev.hmpps.dsd.io/"
  nn_endpoint_url              = "https://notm-dev.hmpps.dsd.io/"
  licences_endpoint_url        = "https://licences-stage.hmpps.dsd.io/"
  prison_staff_hub_ui_url      = "https://prisonstaffhub-dev.hmpps.dsd.io/"
  api_whereabouts_endpoint_url = "https://whereabouts-api.apps.cloud-platform-live-0.k8s.integration.dsd.io/"
  hmpps_cookie_name            = "hmpps-session-dev"
  google_analytics_id          = "UA-106741063-1"
  remote_auth_strategy         = "true"
  update_attendance_enabled    = "true"
}

# Instance and Deployment settings
locals {
  instances = "1"
  mininstances = "0"
  instance_size = "t2.micro"
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-dev"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
