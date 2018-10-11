variable "app-name" {
  type    = "string"
  default = "licences-mock"
}

variable "tags" {
  type = "map"

  default {
    Service     = "Licences"
    Environment = "Mock"
  }
}

# Instance and Deployment settings
locals {
  instances = "1"
  mininstances = "0"
}

# App settings
locals {
  nomis_api_url       = "https://licences-demo-mocks.herokuapp.com/elite2api"
  api_client_id       = "licences"
  pdf_service_host    = "https://licences-nomis-mocks.herokuapp.com"
  domain              = "https://licences-mock.hmpps.dsd.io"
}

# Azure config
locals {
  azurerm_resource_group = "licences-mock"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
