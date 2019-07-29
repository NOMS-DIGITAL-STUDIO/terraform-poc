variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-preprod"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "PreProd"
  }
}

# App settings
locals {
  api_base_endpoint              = "https://gateway.preprod.nomis-api.service.hmpps.dsd.io"
  api_endpoint_url               = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url             = "${local.api_base_endpoint}/auth/"
  api_client_id                  = "elite2apiclient"
  api_system_client_id           = "prisonstaffhubclient"
  keyworker_api_url              = "https://keyworker-api-preprod.service.hmpps.dsd.io/"
  nn_endpoint_url                = "https://notm-preprod.service.hmpps.dsd.io/"
  licences_endpoint_url          = "https://licences-preprod.service.hmpps.dsd.io/"
  prison_staff_hub_ui_url        = "https://prisonstaffhub-preprod.service.hmpps.dsd.io/"
  api_whereabouts_endpoint_url   = "https://whereabouts-api-preprod.service.justice.gov.uk/"
  hmpps_cookie_name              = "hmpps-session-preprod"
  google_analytics_id            = ""
  remote_auth_strategy           = "true"
  update_attendance_prisons      = "ACI,AGI,AKI,ALI,ASI,AWI,AYI,BAI,BCI,BDI,BFI,BHI,BKI,BLI,BMI,BNI,BRI,BSI,BTI,BUI,BWI,BXI,BZI,CDI,CFI,CHI,CKI,CLI,CSI,CWI,CYI,DAI,DGI,DHI,DMI,DNI,DRI,DTI,DVI,DWI,EEI,EHI,ESI,EVI,EWI,EXI,EYI,FBI,FDI,FHI,FKI,FMI,FNI,FSI,GHI,GLI,GMI,GNI,GPI,GTI,HBI,HCI,HDI,HEI,HGI,HHI,HII,HLI,HMI,HOI,HPI,HQGRP,HRI,HVI,HYI,ISI,KMI,KTI,KVI,LAI,LCI,LEI,LFI,LGI,LHI,LIC,LII,LLI,LMI,LNI,LPI,LTI,LWI,LYI,MDI,MHI,MRI,MSI,MTI,NEI,NHI,NLI,NMI,NNI,NSI,NWI,ONI,OWI,PBI,PDI,PFI,PKI,PNI,PRI,PTI,PVI,RCI,RDI,RHI,RNI,RSI,SDI,SFI,SHI,SKI,SLI,SMI,SNI,SPI,STI,SUI,SWI,SYI,TCI,TRN,TSI,UKI,UPI,VEI,WAI,WBI,WCI,WDI,WEI,WHI,WII,WLI,WMI,WNI,WOI,WRI,WSI,WTI,WWI,WYI,ZZGHI,IWI"
  iep_change_link_enabled        = "true"
}

# Instance and Deployment settings
locals {
  instances     = "3"
  mininstances  = "2"
  instance_size = "t2.medium"
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-preprod"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "${var.ips["office"]}/32",
    "${var.ips["quantum"]}/32",
    "${var.ips["quantum_alt"]}/32",
    "${var.ips["health-kick"]}/32",
    "${var.ips["mojvpn"]}/32",
  ]
}
