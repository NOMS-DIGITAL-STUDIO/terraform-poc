variable "app-name" {
  type    = "string"
  default = "prisonstaffhub-dev"
}

variable "tags" {
  type = "map"

  default {
    Service     = "prisonstaffhub"
    Environment = "Dev"
  }
}

# App settings
locals {
  api_base_endpoint              = "https://gateway.t3.nomis-api.hmpps.dsd.io"
  api_endpoint_url               = "${local.api_base_endpoint}/elite2api/"
  oauth_endpoint_url             = "${local.api_base_endpoint}/auth/"
  api_client_id                  = "elite2apiclient"
  api_system_client_id           = "prisonstaffhubclient"
  keyworker_api_url              = "https://keyworker-api-dev.hmpps.dsd.io/"
  nn_endpoint_url                = "https://notm-dev.hmpps.dsd.io/"
  licences_endpoint_url          = "https://licences-stage.hmpps.dsd.io/"
  prison_staff_hub_ui_url        = "https://prisonstaffhub-dev.hmpps.dsd.io/"
  api_whereabouts_endpoint_url   = "https://whereabouts-api-dev.service.justice.gov.uk/"
  api_community_endpoint_url     = "https://community-proxy.apps.live-1.cloud-platform.service.justice.gov.uk/communityapi/"
  hmpps_cookie_name              = "hmpps-session-dev"
  google_analytics_id            = "UA-106741063-1"
  remote_auth_strategy           = "true"
  update_attendance_prisons      = "ACI,AGI,AKI,ALI,ASI,AWI,AYI,BAI,BCI,BDI,BFI,BHI,BKI,BLI,BMI,BNI,BRI,BSI,BTI,BUI,BWI,BXI,BZI,CDI,CFI,CHI,CKI,CLI,CSI,CWI,CYI,DAI,DGI,DHI,DMI,DNI,DRI,DTI,DVI,DWI,EEI,EHI,ESI,EVI,EWI,EXI,EYI,FBI,FDI,FHI,FKI,FMI,FNI,FSI,GHI,GLI,GMI,GNI,GPI,GTI,HBI,HCI,HDI,HEI,HGI,HHI,HII,HLI,HMI,HOI,HPI,HQGRP,HRI,HVI,HYI,ISI,KMI,KTI,KVI,LAI,LCI,LEI,LFI,LGI,LHI,LIC,LII,LLI,LMI,LNI,LPI,LTI,LWI,LYI,MDI,MHI,MRI,MSI,MTI,NEI,NHI,NLI,NMI,NNI,NSI,NWI,ONI,OWI,PBI,PDI,PFI,PKI,PNI,PRI,PTI,PVI,RCI,RDI,RHI,RNI,RSI,SDI,SFI,SHI,SKI,SLI,SMI,SNI,SPI,STI,SUI,SWI,SYI,TCI,TRN,TSI,UKI,UPI,VEI,WAI,WBI,WCI,WDI,WEI,WHI,WII,WLI,WMI,WNI,WOI,WRI,WSI,WTI,WWI,WYI,ZZGHI,IWI"
  iep_change_link_enabled        = "true"
  session_timeout_mins           = "60"
} 

# Instance and Deployment settings
locals {
  instances     = "1"
  mininstances  = "0"
  instance_size = "t2.micro"
}

# Azure config
locals {
  azurerm_resource_group = "prisonstaffhub-dev"
  azure_region           = "ukwest"
}

locals {
  allowed-list = [
    "0.0.0.0/0",
  ]
}
