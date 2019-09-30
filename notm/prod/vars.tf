variable "app-name" {
  type    = "string"
  default = "notm-prod"
}

variable "tags" {
  type = "map"
  default {
    Service     = "NOTM"
    Environment = "Prod"
  }
}

# Instance and Deployment settings
locals {
  instances = "3"
  mininstances = "2"
  instance_size = "t2.medium"
}

locals {
  api_base_endpoint           = "https://gateway.prod.nomis-api.service.hmpps.dsd.io"
  api_endpoint_url            = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url          = "${local.api_base_endpoint}/auth/"
  keyworker_api_url           = "https://keyworker-api.service.hmpps.dsd.io/"
  casenotes_api_url           = "https://offender-case-notes.service.justice.gov.uk"
  categorisation_ui_url       = "https://offender-categorisation.service.justice.gov.uk/"
  nn_endpoint_url             = "https://notm.service.hmpps.dsd.io/"
  omic_ui_url                 = "https://manage-key-workers.service.justice.gov.uk/"
  whereabouts_ui_url          = "https://prisonstaffhub.service.hmpps.dsd.io/whereaboutssearch"
  establishment_rollcheck_url = "https://prisonstaffhub.service.hmpps.dsd.io/establishmentroll"
  prison_staff_hub_ui_url     = "https://prisonstaffhub.service.hmpps.dsd.io/"
  api_client_id               = "elite2apiclient"
  hmpps_cookie_name           = "hmpps-session-prod"
  hmpps_cookie_domain         = "service.hmpps.dsd.io"
  remote_auth_strategy        = "true"
  session_timeout_mins        = "60"
  use_of_force_prisons        = "WRI"
  use_of_force_url            = "https://use-of-force.service.justice.gov.uk"
}

# Azure config
locals {
  azurerm_resource_group = "notm-prod"
  azure_region           = "ukwest"
}

# Allow list of network IPS to access this service
# the /32 subnets are specific host IP addresses
# The /24 subnets allow access from of upto 255 IP addresses
# The /25 subnets allow access from a CIDR block of upto 127 IP addresses

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["quantum_alt"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["digitalprisons1"]}/32",
    "${var.ips["digitalprisons2"]}/32",
    "${var.ips["mojvpn"]}/32",
    "${var.ips["j5-phones-1"]}/32",
    "${var.ips["j5-phones-2"]}/32",
    "${var.ips["sodexo-northumberland"]}/32",
    "${var.ips["thameside-private-prison"]}/32",
    "${var.ips["ark-nps-hmcts-ttp1"]}/24",
    "${var.ips["ark-nps-hmcts-ttp2"]}/25",
    "${var.ips["ark-nps-hmcts-ttp3"]}/25",
    "${var.ips["ark-nps-hmcts-ttp4"]}/25",
    "${var.ips["ark-nps-hmcts-ttp5"]}/25",
    "${var.ips["oakwood"]}/32"
  ]
}


