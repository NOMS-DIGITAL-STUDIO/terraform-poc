variable "app-name" {
  type    = string
  default = "health-kick-stage"
}

variable "tags" {
  type = map

  default = {
    Service     = "health-kick"
    Environment = "Stage"
  }
}

resource "aws_elastic_beanstalk_application" "app" {
  name        = var.app-name
  description = var.app-name
}

data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux .* v2.* running Docker 17.*$"
}

resource "aws_elastic_beanstalk_environment" "app-env" {
  name                = var.app-name
  application         = aws_elastic_beanstalk_application.app.name
  solution_stack_name = data.aws_elastic_beanstalk_solution_stack.docker.name
  tier                = "WebServer"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "InstanceType"
    value     = "t2.micro"
  }

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = "aws-elasticbeanstalk-ec2-role"
  }

   #>>> HEALTH MONITORING

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "ConfigDocument"
    value     = file("../../shared/aws_eb_health_config.json")
  }

  #<<< HEALTH MONITORING

  setting {
    namespace = "aws:elasticbeanstalk:application"
    name      = "Application Healthcheck URL"
    value     = "/health"
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = "aws-elasticbeanstalk-service-role"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "SSLCertificateId"
    value     = aws_acm_certificate.cert.arn
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "InstancePort"
    value     = "80"
  }

  setting {
    namespace = "aws:elb:listener:443"
    name      = "ListenerProtocol"
    value     = "HTTPS"
  }

  setting {
    namespace = "aws:elb:policies:tlshigh"
    name      = "LoadBalancerPorts"
    value     = "443"
  }

  setting {
    namespace = "aws:elb:policies:tlshigh"
    name      = "SSLReferencePolicy"
    value     = local.elb_ssl_policy
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = aws_vpc.vpc.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = aws_subnet.private-a.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = aws_subnet.public-a.id
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "AssociatePublicIpAddress"
    value     = "false"
  }

  setting {
    namespace = "aws:elasticbeanstalk:healthreporting:system"
    name      = "SystemType"
    value     = "enhanced"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "ManagedActionsEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions"
    name      = "PreferredStartTime"
    value     = "Fri:10:00"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "UpdateLevel"
    value     = "minor"
  }

  setting {
    namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
    name      = "InstanceRefreshEnabled"
    value     = "true"
  }

  setting {
    namespace = "aws:elasticbeanstalk:cloudwatch:logs"
    name      = "StreamLogs"
    value     = "true"
  }

  # Begin app-specific config settings

  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }
  tags = var.tags
}

resource "aws_acm_certificate" "cert" {
  domain_name       = "health-kick.hmpps.dsd.io"
  validation_method = "DNS"
  tags              = var.tags
}

locals {
  aws_record_name = replace(aws_acm_certificate.cert.domain_validation_options.0.resource_record_name,local.azure_dns_zone_name,"")
}

resource "azurerm_dns_cname_record" "acm-verify" {
  name                = substr(local.aws_record_name, 0, length(local.aws_record_name)-2)
  zone_name           = local.azure_dns_zone_name
  resource_group_name = local.azure_dns_zone_rg
  ttl                 = "300"
  record              = aws_acm_certificate.cert.domain_validation_options.0.resource_record_value
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "health-kick"
  zone_name           = local.azure_dns_zone_name
  resource_group_name = local.azure_dns_zone_rg
  ttl                 = "60"
  record              = aws_elastic_beanstalk_environment.app-env.cname
}
