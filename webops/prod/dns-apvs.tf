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
