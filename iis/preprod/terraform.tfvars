app = "iis"
env = "preprod"
# set below if creating binding from scratch
#certificate_kv_secret_id=""
certificate_name            = "iis-preprod-iis-preprod-CERThpa-preprodDOTserviceDOThmppsDOTdsdDOTio"
https_only                  = true
ip_restriction_addresses    = ["217.33.148.210/32", "62.25.109.197/32", "212.137.36.230/32", "192.0.2.4/32", "192.0.2.5/32", "192.0.2.6/32", "192.0.2.7/32", "192.0.2.8/32", "192.0.2.9/32", "192.0.2.10/32", "192.0.2.11/32", "192.0.2.12/32", "192.0.2.13/32", "192.0.2.14/32", "192.0.2.15/32", "20.49.225.111/32"]
sc_branch                   = "deploy-to-preprod"
repo_url                    = "https://github.com/ministryofjustice/iis.git"
signon_hostname             = "https://signon.service.justice.gov.uk"
sampling_percentage         = "100"
custom_hostname             = "hpa-preprod.service.hmpps.dsd.io"
has_storage                 = true
scm_use_main_ip_restriction = true
webhook_url                 = "https://$iis-preprod:KvQb7vusM7WLlsrxZXEKZvJGA74jJrvTyBEWcc5wJbpK1KA0KxSbzqeSgx2z@iis-preprod.scm.azurewebsites.net/deploy?scmType=GitHub"
