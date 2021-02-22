module "app_service" {
  source                   = "../../shared/modules/azure-app-service"
  app                      = var.app
  sa_name                 = "${replace(local.name, "-", "")}storage"
  env                      = var.env
  certificate_name         = var.certificate_name
  app_service_kind         = "Windows"
    scm_type                = "LocalGit"
    use_32_bit_worker_process   = false

    app_service_plan_size = "S1"
  azure_jenkins_sp_oid     = var.azure_jenkins_sp_oid
  sampling_percentage      = var.sampling_percentage
  custom_hostname          = var.custom_hostname
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
