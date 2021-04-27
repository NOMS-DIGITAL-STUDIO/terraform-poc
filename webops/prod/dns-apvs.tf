resource "azurerm_dns_zone" "help_with_prison_visits" {
  provider            = azurerm.apvs
  name                = "help-with-prison-visits.service.gov.uk"
  resource_group_name = "apvs-prd"

  soa_record {
    email         = "azuredns-hostmaster.microsoft.com"
    expire_time   = "2419200"
    host_name     = "ns1-01.azure-dns.com."
    minimum_ttl   = "300"
    refresh_time  = "3600"
    retry_time    = "300"
    serial_number = "1"
    ttl           = "3600"
  }
}

resource "azurerm_dns_a_record" "hwpv_zone_a_record" {
  provider            = azurerm.apvs
  name                = "@"
  records             = ["51.140.33.178"]
  resource_group_name = "apvs-prd"
  ttl                 = "3600"
  zone_name           = azurerm_dns_zone.help_with_prison_visits.name
}

resource "azurerm_dns_cname_record" "apvs_hash_like_cname" {
  provider            = azurerm.apvs
  name                = "_2a3b27e3fa8e6bd6d4ef293959a61090"
  record              = "F736B151242EB8C7157E075B583488FC.92432E487F3EE5E8F539715731ED6B6D.b856bd4b563970cc9920.comodoca.com."
  resource_group_name = "apvs-prd"
  ttl                 = "3600"
  zone_name           = azurerm_dns_zone.help_with_prison_visits.name
}

resource "azurerm_dns_cname_record" "apvs_caseworker" {
  provider            = azurerm.apvs
  name                = "caseworker"
  record              = "e0e8c2cb-80cc-4087-a192-3b8fb4b49b2a.cloudapp.net"
  resource_group_name = "apvs-prd"
  ttl                 = "3600"
  zone_name           = azurerm_dns_zone.help_with_prison_visits.name
}

resource "azurerm_dns_ns_record" "apvs_zone_ns_record" {
  provider            = azurerm.apvs
  name                = "@"
  records             = ["ns1-01.azure-dns.com.", "ns2-01.azure-dns.net.", "ns3-01.azure-dns.org.", "ns4-01.azure-dns.info."]
  resource_group_name = "apvs-prd"
  ttl                 = "172800"
  zone_name           = azurerm_dns_zone.help_with_prison_visits.name
}

resource "azurerm_dns_txt_record" "apvs_acme_challenge" {
  provider = azurerm.apvs
  name     = "_acme-challenge"

  record {
    value = "IB3suKjtigmB8tOSQNMJlDRnLm3eR9xJfNHA-NogkrE"
  }

  resource_group_name = "apvs-prd"
  ttl                 = "10"
  zone_name           = azurerm_dns_zone.help_with_prison_visits.name
}
