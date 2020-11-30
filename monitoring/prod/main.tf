module "monitoring" {
  source           = "../../aws-modules/monitoring"
  environment-name = local.environment_name
  key-pair-name    = local.key_pair_name
  application-name = local.application_name
  dns-zone-name    = local.dns_zone_name
  dns-zone-rg      = local.dns_zone_rg
}

locals {
  environment_name = var.environment-name
  key_pair_name    = var.key-pair-name
  application_name = var.application-name
  dns_zone_name    = var.dns-zone-name
  dns_zone_rg      = var.dns-zone-rg
}
