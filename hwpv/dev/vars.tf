locals {
  name    = "hwpv"
  dnszone = "hwpv.hmpps.dsd.io"

  tags = {
    Service     = "HWPV"
    Environment = "MGMT"
  }
}
