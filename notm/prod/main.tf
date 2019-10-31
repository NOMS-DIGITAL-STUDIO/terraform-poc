resource "aws_security_group" "elb" {

  name        = "${var.app-name}-elb"
  vpc_id      = "${aws_vpc.vpc.id}"
  description = "ELB"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = "${local.allowed-list}"
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = "${local.allowed-list}"
  }

  egress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = "${merge(map("Name", "${var.app-name}-elb"), var.tags)}"

  lifecycle {
    create_before_destroy = true
  }
}


resource "aws_lb" "redirect" {
  name               = "redirect-${var.app-name}"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${aws_security_group.elb.id}"]
  subnets            = ["${aws_subnet.public-a.id}","${aws_subnet.public-b.id}"]
  tags               = "${var.tags}"
}

resource "aws_lb_listener" "redirect" {
  load_balancer_arn = "${aws_lb.redirect.arn}"
  port              = "443"
  protocol          = "HTTPS"
  ssl_policy        = "${local.elb_ssl_policy}"
  certificate_arn   = "${aws_acm_certificate.cert.arn}"

#  default_action {
#    type = "fixed-response"
#
#    fixed_response {
#      content_type = "text/plain"
#      message_body = "This site has moved to https://digital.prison.service.justice.gov.uk\nPlease update your bookmarks."
#      status_code  = "200"
#    }
#  }

  default_action {
   type = "redirect"
    redirect {
      host = "digital.prison.service.justice.gov.uk"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}

resource "aws_lb_listener" "redirect_to_443" {
  load_balancer_arn = "${aws_lb.redirect.arn}"
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "redirect"

    redirect {
      port = "443"
      protocol = "HTTPS"
      status_code = "HTTP_301"
    }
  }
}


locals {
  cname = "${replace(var.app-name,"-prod","")}"
}

# Allow AWS's ACM to manage the apps FQDN
resource "aws_acm_certificate" "cert" {
  domain_name       = "${local.cname}.${local.azure_dns_zone_name}"
  validation_method = "DNS"
  tags              = "${var.tags}"
}

resource "azurerm_dns_cname_record" "cname" {
  name                = "${local.cname}"
  zone_name           = "${local.azure_dns_zone_name}"
  resource_group_name = "${local.azure_dns_zone_rg}"
  ttl                 = "60"
  record              = "${aws_lb.redirect.dns_name}"
}


locals {
  aws_record_name = "${replace(aws_acm_certificate.cert.domain_validation_options.0.resource_record_name,local.azure_dns_zone_name,"")}"
}

//resource "azurerm_dns_cname_record" "acm-verify" {
//  name                = "${substr(local.aws_record_name, 0, length(local.aws_record_name)-2)}"
//  zone_name           = "${local.azure_dns_zone_name}"
//  resource_group_name = "${local.azure_dns_zone_rg}"
//  ttl                 = "300"
//  record              = "${aws_acm_certificate.cert.domain_validation_options.0.resource_record_value}"
//}
