output "monitoring_dns_urls" {
  value = [aws_instance.monitoring_ec2_instance.public_dns, "dso-${local.default_application_name}-${local.default_environment_name}.${local.default_dns_zone}"]
}

output "monitoring_ip" {
  value = aws_eip.monitoring_eip.public_ip
}
