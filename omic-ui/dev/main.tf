terraform {
    required_version = ">= 0.9.8"
    backend "s3" {
        bucket = "moj-studio-webops-terraform"
        key = "omic-dev.terraform.tfstate"
        region = "eu-west-2"
        encrypt = true
    }
}

variable "app-name" {
    type = "string"
    default = "omic-dev"
}
variable "tags" {
    type = "map"
    default {
        Service = "omic"
        Environment = "Dev"
    }
}

resource "aws_elastic_beanstalk_application" "app" {
    name = "${var.app-name}"
    description = "${var.app-name}"
}

data "aws_acm_certificate" "cert" {
    domain = "omic-dev.hmpps.dsd.io"
}

resource "aws_elastic_beanstalk_environment" "app-env" {
    name = "${var.app-name}"
    application = "${aws_elastic_beanstalk_application.app.name}"
    solution_stack_name = "${var.elastic-beanstalk-single-docker}"
    tier = "WebServer"

    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "InstanceType"
        value = "t2.micro"
    }
    setting {
        namespace = "aws:autoscaling:launchconfiguration"
        name = "IamInstanceProfile"
        value = "aws-elasticbeanstalk-ec2-role"
    }
    setting {
        namespace = "aws:elasticbeanstalk:application"
        name = "Application Healthcheck URL"
        value = "/health"
    }
    setting {
        namespace = "aws:elasticbeanstalk:environment"
        name = "ServiceRole"
        value = "aws-elasticbeanstalk-service-role"
    }
    setting {
        namespace = "aws:elb:listener:443"
        name = "ListenerProtocol"
        value = "HTTPS"
    }
    setting {
        namespace = "aws:elb:listener:443"
        name = "SSLCertificateId"
        value = "${data.aws_acm_certificate.cert.arn}"
    }
    setting {
        namespace = "aws:elb:listener:443"
        name = "InstancePort"
        value = "80"
    }
    setting {
        namespace = "aws:elb:listener:443"
        name = "ListenerProtocol"
        value = "HTTPS"
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "VPCId"
        value = "${aws_vpc.vpc.id}"
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "Subnets"
        value = "${aws_subnet.private-a.id}"
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "ELBSubnets"
        value = "${aws_subnet.public-a.id}"
    }
    setting {
        namespace = "aws:ec2:vpc"
        name = "AssociatePublicIpAddress"
        value = "false"
    }
    setting {
        namespace = "aws:elasticbeanstalk:healthreporting:system"
        name = "SystemType"
        value = "enhanced"
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions"
        name = "ManagedActionsEnabled"
        value = "true"
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions"
        name = "PreferredStartTime"
        value = "Fri:10:00"
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
        name = "UpdateLevel"
        value = "minor"
    }
    setting {
        namespace = "aws:elasticbeanstalk:managedactions:platformupdate"
        name = "InstanceRefreshEnabled"
        value = "true"
    }

    setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = "USE_API_GATEWAY_AUTH"
      value = "yes"
    }
    setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = "API_ENDPOINT_URL"
      value = "https://noms-api-dev.dsd.io/elite2api/"
    }
    setting {
        namespace = "aws:elasticbeanstalk:application:environment"
        name = "KEYWORKER_API_URL"
        value = "https://keyworker-api-dev.hmpps.dsd.io/"
    }
    setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = "API_GATEWAY_TOKEN"
      value = "${data.aws_ssm_parameter.api-gateway-token.value}"
    }
    setting {
        namespace = "aws:elasticbeanstalk:application:environment"
        name = "API_CLIENT_ID"
        value = "elite2apiclient"
    }
    setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = "API_CLIENT_SECRET"
      value = "${data.aws_ssm_parameter.api-client-secret.value}"
    }
    setting {
      namespace = "aws:elasticbeanstalk:application:environment"
      name = "API_GATEWAY_PRIVATE_KEY"
      value = "${data.aws_ssm_parameter.api-gateway-private-key.value}"
    }
    setting {
        namespace = "aws:elasticbeanstalk:application:environment"
        name = "APPINSIGHTS_INSTRUMENTATIONKEY"
        value = "${data.aws_ssm_parameter.appinsights-instrumentationkey.value}"
    }
    setting {
        namespace = "aws:elasticbeanstalk:application:environment"
        name = "HMPPS_COOKIE_NAME"
        value = "hmpps-session-dev"
    }
    setting {
        namespace = "aws:elasticbeanstalk:application:environment"
        name = "HMPPS_COOKIE_DOMAIN"
        value = "hmpps.dsd.io"
    }
    setting {
        namespace = "aws:elasticbeanstalk:application:environment"
        name = "HMPPS_COOKIE_SECRET"
        value = "${data.aws_ssm_parameter.hmpps-cookie-secret.value}"
    }
    tags = "${var.tags}"
}

resource "azurerm_dns_cname_record" "cname" {
    name = "omic-dev"
    zone_name = "hmpps.dsd.io"
    resource_group_name = "webops"
    ttl = "60"
    record = "${aws_elastic_beanstalk_environment.app-env.cname}"
}
