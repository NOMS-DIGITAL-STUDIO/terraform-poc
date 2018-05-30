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

# This resource is managed in multiple places (prisonstaffhub stage)
resource "aws_elastic_beanstalk_application" "app" {
  name        = "prisonstaffhub"
  description = "prisonstaffhub"
}

resource "random_id" "session-secret" {
  byte_length = 40
}

resource "azurerm_resource_group" "group" {
  name     = "prisonstaffhub-dev"
  location = "ukwest"
  tags     = "${var.tags}"
}

resource "azurerm_application_insights" "insights" {
  name                = "${var.app-name}"
  location            = "North Europe"
  resource_group_name = "${azurerm_resource_group.group.name}"
  application_type    = "Web"
}

resource "aws_acm_certificate" "cert" {
  domain_name = "${var.app-name}.${var.dns_zone_name}"
  validation_method = "DNS"
  tags = "${var.tags}"
}


data "aws_elastic_beanstalk_solution_stack" "docker" {
  most_recent = true
  name_regex  = "^64bit Amazon Linux .* v2.* running Docker 17.*$"
}

resource "aws_elastic_beanstalk_environment" "app-env" {
  name                = "${var.app-name}"
  application         = "${aws_elastic_beanstalk_application.app.name}"
  solution_stack_name = "${data.aws_elastic_beanstalk_solution_stack.docker.name}"
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
    value     = "${aws_acm_certificate.cert.arn}"
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
    value     = "ELBSecurityPolicy-TLS-1-2-2017-01"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "VPCId"
    value     = "${aws_vpc.vpc.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "Subnets"
    value     = "${aws_subnet.private-a.id}"
  }

  setting {
    namespace = "aws:ec2:vpc"
    name      = "ELBSubnets"
    value     = "${aws_subnet.public-a.id}"
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
    name      = "USE_API_GATEWAY_AUTH"
    value     = "yes"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_ENDPOINT_URL"
    value     = "https://noms-api-dev.dsd.io/elite2api/"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NN_ENDPOINT_URL"
    value     = "https://notm-dev.hmpps.dsd.io/"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_TOKEN"
    value     = "${data.aws_ssm_parameter.api-gateway-token.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_CLIENT_ID"
    value     = "elite2apiclient"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_CLIENT_SECRET"
    value     = "${data.aws_ssm_parameter.api-client-secret.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "API_GATEWAY_PRIVATE_KEY"
    value     = "${data.aws_ssm_parameter.api-gateway-private-key.value}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "APPINSIGHTS_INSTRUMENTATIONKEY"
    value     = "${azurerm_application_insights.insights.instrumentation_key}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "HMPPS_COOKIE_NAME"
    value     = "hmpps-session-dev"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "HMPPS_COOKIE_DOMAIN"
    value     = "hmpps.dsd.io"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "SESSION_COOKIE_SECRET"
    value     = "${random_id.session-secret.b64}"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "NODE_ENV"
    value     = "production"
  }
  setting {
    namespace = "aws:elasticbeanstalk:application:environment"
    name      = "GOOGLE_ANALYTICS_ID"
    value     = "UA-106741063-1"
  }
  tags = "${var.tags}"
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "${var.app-name}"
  zone_name           = "hmpps.dsd.io"
  resource_group_name = "webops"
  ttl                 = "60"
  record              = "${aws_elastic_beanstalk_environment.app-env.cname}"
}

# Allow AWS's ACM to manage prisonstaffhub-dev.hmpps.dsd.io
locals {
  aws_record_name     = "${replace(aws_acm_certificate.cert.domain_validation_options.0.resource_record_name,var.dns_zone_name,"")}"
}

resource "azurerm_dns_cname_record" "acm-verify" {
  name                = "${substr(local.aws_record_name, 0, length(local.aws_record_name)-2)}"
  zone_name           = "${var.dns_zone_name}"
  resource_group_name = "webops"
  ttl                 = "300"
  record              = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"
}
