resource "azurerm_dns_zone" "offloc_service_justice_gov_uk" {
  name                = "offloc.service.justice.gov.uk"
  resource_group_name = local.name
  tags                = var.tags

  soa_record {
    email         = "azuredns-hostmaster.microsoft.com"
    expire_time   = "2419200"
    host_name     = "ns1-09.azure-dns.com."
    minimum_ttl   = "300"
    refresh_time  = "3600"
    retry_time    = "300"
    serial_number = "1"
    ttl           = "3600"
  }

}

resource "azurerm_dns_ns_record" "zone_ns_record" {
  name                = "@"
  records             = ["ns1-09.azure-dns.com.", "ns2-09.azure-dns.net.", "ns3-09.azure-dns.org.", "ns4-09.azure-dns.info."]
  resource_group_name = local.name
  ttl                 = "172800"
  zone_name           = azurerm_dns_zone.offloc_service_justice_gov_uk.name
}

resource "azurerm_dns_cname_record" "www" {
  name                = "www"
  record              = "offloc-prod.azurewebsites.net"
  resource_group_name = local.name
  ttl                 = "300"
  zone_name           = azurerm_dns_zone.offloc_service_justice_gov_uk.name
}
