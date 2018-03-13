resource "aws_vpc" "vpc" {
    cidr_block = "192.168.0.0/26"
    instance_tenancy = "default"
    enable_dns_support = true
    enable_dns_hostnames = false
    tags = "${merge(var.tags, map("Name", var.app-name))}"
}
resource "aws_subnet" "public-a" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "192.168.0.0/28"
  availability_zone = "${var.aws_az_a}"
  tags = "${merge(var.tags, map("Name", "${var.app-name}-public-a"))}"
}

resource "aws_subnet" "private-a" {
  vpc_id     = "${aws_vpc.vpc.id}"
  cidr_block = "192.168.0.32/28"
  availability_zone = "${var.aws_az_a}"
  tags = "${merge(var.tags, map("Name", "${var.app-name}-private-a"))}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags = "${merge(var.tags, map("Name", var.app-name))}"
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
  tags = "${merge(var.tags, map("Name", var.app-name))}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

