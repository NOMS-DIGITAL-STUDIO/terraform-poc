resource "azurerm_dns_zone" "service-hmpps" {
  name                = "service.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_ns_record" "nomis-api" {
  name                = "nomis-api"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = 300

  records = ["ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns1-07.azure-dns.com.", "ns4-07.azure-dns.info."]

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

output "service_hmpps_dsd_io_namesevers" {
  value = [azurerm_dns_zone.service-hmpps.name_servers]
}

resource "azurerm_dns_zone" "az_justice_gov_uk" {
  name                = "az.justice.gov.uk"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_zone" "studio-hosting" {
  name                = "studio-hosting.service.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags                = var.tags
}

resource "azurerm_dns_ns_record" "studio-hosting" {
  name                = "studio-hosting"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = 300
  records             = ["ns4-07.azure-dns.info.", "ns3-07.azure-dns.org.", "ns2-07.azure-dns.net.", "ns1-07.azure-dns.com."]
  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_a_record" "reporting_lsast_nomis" {
  name                = "reporting.lsast-nomis"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  records             = ["10.40.44.198"]
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_oasys" {
  name                = "bridge-oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_onr" {
  name                = "bridge-onr"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "onr-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_pp_oasys" {
  name                = "bridge-pp-oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-preprod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_pp_onr" {
  name                = "bridge-pp-onr"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "onr-preprod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "bridge_practice_oasys" {
  name                = "bridge-practice.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 3600
}

resource "azurerm_dns_cname_record" "bridge_training_oasys" {
  name                = "bridge-training.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 3600
}

resource "azurerm_dns_cname_record" "practice_oasys" {
  name                = "practice.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}

resource "azurerm_dns_cname_record" "training_oasys" {
  name                = "training.oasys"
  zone_name           = azurerm_dns_zone.az_justice_gov_uk.name
  resource_group_name = azurerm_resource_group.group.name
  record              = "oasys-prod.uksouth.cloudapp.azure.com"
  ttl                 = 300
}
