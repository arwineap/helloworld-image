# Specify the provider details
provider "aws" {
    version = "~> 2.21"
    region  = "us-east-1"
}

provider "template" {
  version    = "~> 2.1"
}

terraform {
  backend "s3" {
    bucket = "int-terraform-state-1564544704"
    key    = "terraform.tfstate"
    region = "us-east-1"
  }
}

# Create a VPC
resource "aws_vpc" "vpc" {
    cidr_block           = "${var.cidr}"
    enable_dns_support   = true
    enable_dns_hostnames = true

    tags {
        Name = "int-vpc"
    }
}

resource "aws_internet_gateway" "main" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "int-igw"
  }
}

resource "aws_eip" "nat" {
  count = "${length(split(",", data.template_file.external_subnets.rendered))}"
  vpc   = true
}

resource "aws_nat_gateway" "main" {
  # 3 AZ
  count         = "${length(split(",", data.template_file.external_subnets.rendered))}"
  allocation_id = "${element(aws_eip.nat.*.id, count.index)}"
  subnet_id     = "${element(aws_subnet.external.*.id, count.index)}"
  depends_on    = ["aws_internet_gateway.main"]
}

// cidrsubnet takes 3 parameters
// cidrsubnet(prefix, newbits, netnum)
// Assuming a CIDR of 10.0.0.0/16, this will yield a string like: "10.0.0.0/21,10.0.32.0/21",10.0.64.0/21"
data "template_file" "external_subnets" {
  template = "$${external_subnet_list}"
  vars {
    external_subnet_list = "${cidrsubnet(cidrsubnet("${var.cidr}", 3, 0), 2, 0)},${cidrsubnet(cidrsubnet("${var.cidr}", 3, 1), 2, 0)},${cidrsubnet(cidrsubnet("${var.cidr}", 3, 2), 2, 0)}"
  }
}

// cidrsubnet takes 3 parameters
// cidrsubnet(prefix, newbits, netnum)
// Assuming a CIDR of 10.0.0.0/16, this will yield a string like: "10.0.8.0/21,10.0.40.0/21",10.0.72.0/21"
data "template_file" "internal_subnets" {
  template = "$${internal_subnet_list}"
  vars {
    internal_subnet_list = "${cidrsubnet(cidrsubnet("${var.cidr}", 3, 0), 2, 1)},${cidrsubnet(cidrsubnet("${var.cidr}", 3, 1), 2, 1)},${cidrsubnet(cidrsubnet("${var.cidr}", 3, 2), 2, 1)}"
  }
}

resource "aws_subnet" "internal" {
  vpc_id            = "${aws_vpc.vpc.id}"
  cidr_block        = "${element(split(",", data.template_file.internal_subnets.rendered), count.index)}"
  availability_zone = "${element(var.availability_zones, count.index)}"
  count             = "${length(split(",", data.template_file.internal_subnets.rendered))}"

  tags {
    Name        = "internal"
  }
}

resource "aws_subnet" "external" {
  vpc_id                  = "${aws_vpc.vpc.id}"
  cidr_block              = "${element(split(",", data.template_file.external_subnets.rendered), count.index)}"
  availability_zone       = "${element(var.availability_zones, count.index)}"
  count                   = "${length(split(",", data.template_file.external_subnets.rendered))}"
  map_public_ip_on_launch = true

  tags {
    Name        = "external"
  }
}

resource "aws_route_table" "external" {
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "external"
  }
}

resource "aws_route" "external" {
  route_table_id         = "${aws_route_table.external.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.main.id}"
}

resource "aws_route_table" "internal" {
  count  = "${length(split(",", data.template_file.internal_subnets.rendered))}"
  vpc_id = "${aws_vpc.vpc.id}"

  tags {
    Name        = "internal"
  }
}

resource "aws_route" "internal" {
  count                  = "${length(split(",", data.template_file.internal_subnets.rendered))}"
  route_table_id         = "${element(aws_route_table.internal.*.id, count.index)}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${element(aws_nat_gateway.main.*.id, count.index)}"
}

resource "aws_route_table_association" "internal" {
  count          = "${length(split(",", data.template_file.internal_subnets.rendered))}"
  subnet_id      = "${element(aws_subnet.internal.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.internal.*.id, count.index)}"
}

resource "aws_route_table_association" "external" {
  count          = "${length(split(",", data.template_file.external_subnets.rendered))}"
  subnet_id      = "${element(aws_subnet.external.*.id, count.index)}"
  route_table_id = "${aws_route_table.external.id}"
}
