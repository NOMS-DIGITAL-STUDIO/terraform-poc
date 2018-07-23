variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-api-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub-api"
    Environment = "Dev"
  }
}

# Instance and Deployment settings
locals {
  instances = "1"
  mininstances = "0"
}

locals {
  elite2_uri_root        = "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api"
  server_timeout         = "60000"
  azurerm_resource_group = "prisonstaffhub-api-dev"
  azure_region           = "ukwest"
}
