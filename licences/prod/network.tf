resource "aws_vpc" "vpc" {
  cidr_block           = "192.168.0.0/24"
  instance_tenancy     = "default"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags                 = "${merge(var.tags, map("Name", var.app-name))}"
}

resource "aws_subnet" "public-a" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.0/28"
  availability_zone = "${var.aws_az_a}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-dmz-a"))}"
}

resource "aws_subnet" "public-b" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.16/28"
  availability_zone = "${var.aws_az_b}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-dmz-b"))}"
}

resource "aws_subnet" "private-a" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.32/28"
  availability_zone = "${var.aws_az_a}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-app-a"))}"
}

resource "aws_subnet" "private-b" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.160/28"
  availability_zone = "${var.aws_az_b}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-app-b"))}"
}


resource "aws_subnet" "db-a" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.64/28"
  availability_zone = "${var.aws_az_a}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-db-a"))}"
}

resource "aws_subnet" "db-b" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "192.168.0.96/28"
  availability_zone = "${var.aws_az_b}"
  tags              = "${merge(var.tags, map("Name", "${var.app-name}-db-b"))}"
}

resource "aws_internet_gateway" "gw" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags   = "${merge(var.tags, map("Name", var.app-name))}"
}

resource "aws_eip" "nat-a" {
  vpc = true
}

resource "aws_eip" "nat-b" {
  vpc = true
}

resource "aws_nat_gateway" "gw-a" {
  allocation_id = "${aws_eip.nat-a.id}"
  subnet_id     = "${aws_subnet.public-a.id}"
  depends_on    = ["aws_internet_gateway.gw"]
}

resource "aws_nat_gateway" "gw-b" {
  allocation_id = "${aws_eip.nat-b.id}"
  subnet_id     = "${aws_subnet.public-b.id}"
  depends_on    = ["aws_internet_gateway.gw"]
}

resource "aws_default_route_table" "default" {
  default_route_table_id = "${aws_vpc.vpc.default_route_table_id}"
  tags                   = "${merge(var.tags, map("Name", var.app-name))}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.gw.id}"
  }
}

resource "aws_route_table" "private-a" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags   = "${merge(var.tags, map("Name", "${var.app-name}-private"))}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw-a.id}"
  }
}

resource "aws_route_table" "private-b" {
  vpc_id = "${aws_vpc.vpc.id}"
  tags   = "${merge(var.tags, map("Name", "${var.app-name}-private"))}"

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = "${aws_nat_gateway.gw-b.id}"
  }
}

resource "aws_route_table_association" "private-a" {
  subnet_id      = "${aws_subnet.private-a.id}"
  route_table_id = "${aws_route_table.private-a.id}"
}

resource "aws_route_table_association" "private-b" {
  subnet_id      = "${aws_subnet.private-b.id}"
  route_table_id = "${aws_route_table.private-b.id}"
}
