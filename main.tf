provider "aws" {
  region = var.region
}

resource "aws_vpc" "main" {
  cidr_block = var.vpc_cidr
  enable_dns_support = true
  enable_dns_hostnames = true

  tags = {
    Name = "${var.env}-vpc"
    Environment = var.env
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${var.env}-igw"
  }
}

resource "aws_subnet" "public" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index)
  availability_zone = element(var.azs, count.index)
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.env}-public-${count.index}"
  }
}

resource "aws_subnet" "private" {
  count             = 3
  vpc_id            = aws_vpc.main.id
  cidr_block        = cidrsubnet(var.vpc_cidr, 4, count.index + 3)
  availability_zone = element(var.azs, count.index)

  tags = {
    Name = "${var.env}-private-${count.index}"
  }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "${var.env}-nat"
  }

  depends_on = [aws_internet_gateway.igw]
}

resource "aws_eip" "nat" {
  domain = "vpc"
  tags = {
    Name = "${var.env}-nat-eip"
  }
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "${var.env}-public-rt"
  }
}

resource "aws_route_table_association" "public" {
  count          = 3
  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }

  tags = {
    Name = "${var.env}-private-rt"
  }
}

resource "aws_route_table_association" "private" {
  count          = 3
  subnet_id      = aws_subnet.private[count.index].id
  route_table_id = aws_route_table.private.id
}

resource "aws_networkfirewall_firewall_policy" "fw_policy" {
  name = "${var.env}-fw-policy"

  firewall_policy {
  stateless_default_actions          = ["aws:forward_to_sfe"]
  stateless_fragment_default_actions = ["aws:forward_to_sfe"]

  stateless_rule_group_reference {
    priority     = 10
    resource_arn = aws_networkfirewall_rule_group.stateless.arn
  }

  stateful_rule_group_reference {
    resource_arn = aws_networkfirewall_rule_group.stateful.arn
  }
}

}

resource "aws_networkfirewall_rule_group" "stateless" {
  name     = "${var.env}-stateless"
  type     = "STATELESS"
  capacity = 100

  rule_group {
    rules_source {
      stateless_rules_and_custom_actions {
        stateless_rule {
          priority = 1
          rule_definition {
            actions = ["aws:pass"]
            match_attributes {
              protocols      = [6]
              destination_port {
                from_port = 80
                to_port   = 80
              }
              destination_port {
                from_port = 443
                to_port   = 443
              }
              destination {
                address_definition = "0.0.0.0/0"
              }
            }
          }
        }
      }
    }
  }
}

resource "aws_networkfirewall_rule_group" "stateful" {
  name     = "${var.env}-stateful"
  type     = "STATEFUL"
  capacity = 100

  rule_group {
    rules_source {
      rules_string = <<EOF
pass tcp any any -> any 80 (msg:"Allow HTTP"; sid:1001;)
pass tcp any any -> any 443 (msg:"Allow HTTPS"; sid:1002;)
drop ip any any -> 198.51.100.1 any (msg:"Block access to 198.51.100.1"; sid:1003;)
EOF
    }
  }

  tags = {
    Name = "${var.env}-stateful"
  }
}


resource "aws_networkfirewall_firewall" "firewall" {
  name                = "${var.env}-firewall"
  firewall_policy_arn = aws_networkfirewall_firewall_policy.fw_policy.arn
  vpc_id              = aws_vpc.main.id
  subnet_mapping {
    subnet_id = aws_subnet.private[0].id
  }

  tags = {
    Name = "${var.env}-firewall"
  }
}
