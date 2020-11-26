resource "azurerm_dns_zone" "service-hmpps" {
  name                = "service.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "nomis-api" {
  name                = "nomis-api"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = "300"

  records = ["ns1-07.azure-dns.com.", "ns2-07.azure-dns.net.", "ns3-07.azure-dns.org.", "ns4-07.azure-dns.info."]

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

  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_zone" "studio-hosting" {
  name                = "studio-hosting.service.hmpps.dsd.io"
  resource_group_name = azurerm_resource_group.group.name
  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}

resource "azurerm_dns_ns_record" "studio-hosting" {
  name                = "studio-hosting"
  zone_name           = azurerm_dns_zone.service-hmpps.name
  resource_group_name = azurerm_resource_group.group.name
  ttl                 = 300
  records             = azurerm_dns_zone.service-hmpps.name_servers
  tags = {
    Service     = "WebOps"
    Environment = "Management"
  }
}
