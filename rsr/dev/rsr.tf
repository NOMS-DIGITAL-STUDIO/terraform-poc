


module "app_service" {
  source                   = "../../shared/modules/azure-app-service"
  app                      = var.app
  env                      = var.env
  certificate_name         = var.certificate_name
  https_only               = true
  http2_enabled            = true
  app_service_kind         = "Windows"
    scm_type                = "LocalGit"
  azure_jenkins_sp_oid     = var.azure_jenkins_sp_oid
  sampling_percentage      = var.sampling_percentage
  custom_hostname          = var.custom_hostname
  sa_name                 = "${replace(local.name, "-", "")}storage"
default_documents = [
    "Default.htm",
    "Default.html",
    "Default.asp",
    "index.htm",
    "index.html",
    "iisstart.htm",
    "default.aspx",
    "index.php",
    "hostingstart.html",
  ]
  tags = var.tags
  }

resource "github_repository_webhook" "rsr-deploy" {
  repository = "rsr-calculator-service"
  configuration {
    #hardcoded if this is ever rebuilt will need to be updated
    url          = "https://$rsr-dev:xfyC59uSQz6pakG3981G86u261Bh7yiuHLmYaqndksjPtGGDuDbeLeQNcLGa@rsr-dev.scm.azurewebsites.net/deploy?scmType=GitHub"
    content_type = "form"
    insecure_ssl = false
  }

  active = true

  events = ["push"]
}
