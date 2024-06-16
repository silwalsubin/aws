provider "aws" {
  region = "us-east-1" # Specify your preferred region
}

# Check for Existing VPCs with the Specified Name Tag
data "aws_vpcs" "existing" {
  filter {
    name   = "tag:Name"
    values = ["MyVPC"]  # Replace with the desired VPC name tag
  }
}

# Conditionally create a new VPC if none with the specified name tag exists
resource "aws_vpc" "my_vpc" {
  count                = length(data.aws_vpcs.existing.ids) == 0 ? 1 : 0
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "MyVPC"  # This is the tag name to identify the VPC
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Check for Existing Subnet and Create if it Doesn't Exist
data "aws_subnets" "existing" {
  filter {
    name   = "tag:Name"
    values = ["MySubnet"]  # Replace with your Subnet name
  }
}

resource "aws_subnet" "my_subnet" {
  count                  = length(data.aws_subnets.existing.ids) == 0 ? 1 : 0
  vpc_id                 = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : aws_vpc.my_vpc[0].id
  cidr_block             = "10.0.1.0/24"
  map_public_ip_on_launch = true

  tags = {
    Name = "MySubnet"
  }

  lifecycle {
    prevent_destroy = false
  }
}

data "aws_internet_gateway" "attached_igw" {
  count = length(data.aws_vpcs.existing.ids) > 0 ? 1 : 0
  filter {
    name   = "attachment.vpc-id"
    values = length(data.aws_vpcs.existing.ids) > 0 ? [data.aws_vpcs.existing.ids[0]] : []
  }
}

resource "aws_internet_gateway" "my_igw" {
  count  = length(data.aws_internet_gateway.attached_igw) == 0 ? 1 : 0
  vpc_id = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : aws_vpc.my_vpc[0].id

  tags = {
    Name = "MyInternetGateway"
  }

  lifecycle {
    prevent_destroy = false
  }
}

# Check for Existing Route Table and Create if it Doesn't Exist
data "aws_route_tables" "existing" {
  filter {
    name   = "tag:Name"
    values = ["MyRouteTable"]  # Replace with your Route Table name
  }
}

resource "aws_route_table" "my_route_table" {
  count  = length(data.aws_route_tables.existing.ids) == 0 ? 1 : 0
  vpc_id = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : aws_vpc.my_vpc[0].id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = length(data.aws_internet_gateway.attached_igw) > 0 ? data.aws_internet_gateway.attached_igw[0].id : aws_internet_gateway.my_igw[0].id
  }

  tags = {
    Name = "MyRouteTable"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "aws_route_table_association" "my_route_table_association" {
  count          = length(data.aws_route_tables.existing.id) == 0 ? 1 : 0
  subnet_id      = length(data.aws_subnets.existing.id) > 0 ? data.aws_subnets.existing.id : aws_subnet.my_subnet[0].id
  route_table_id = length(data.aws_route_tables.existing.id) > 0 ? data.aws_route_tables.existing.id : aws_route_table.my_route_table[0].id
}

# Check for Existing Security Group and Create if it Doesn't Exist
data "aws_security_groups" "existing" {
  filter {
    name   = "tag:Name"
    values = ["MySecurityGroup"]  # Replace with your Security Group name
  }
}

resource "aws_security_group" "my_security_group" {
  count  = length(data.aws_security_groups.existing.ids) == 0 ? 1 : 0
  name        = "allow_rdp"
  description = "Allow RDP traffic"
  vpc_id      = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : aws_vpc.my_vpc[0].id

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "MySecurityGroup"
  }

  lifecycle {
    prevent_destroy = false
  }
}

resource "tls_private_key" "my_key" {
  algorithm = "RSA"
  rsa_bits  = 2048

  lifecycle {
    prevent_destroy = false
  }
}

# Check for Existing Key Pair
data "aws_key_pair" "existing" {
  key_name = "my_key_pair"
}

locals {
  key_pair_exists = try(data.aws_key_pair.existing.key_name != "", false)
}

resource "aws_key_pair" "my_key_pair" {
  count  = local.key_pair_exists ? 0 : 1
  key_name   = "my_key_pair"
  public_key = tls_private_key.my_key.public_key_openssh

  lifecycle {
    prevent_destroy = false
  }
}

data "aws_vpc" "existing_vpc_details" {
  count = length(data.aws_vpcs.existing.ids) > 0 ? 1 : 0
  id    = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : null
}

# Outputs to display the details of the VPC
output "vpc_id" {
  value = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : aws_vpc.my_vpc[0].id
}

output "vpc_cidr_block" {
  value = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpc.existing_vpc_details[0].cidr_block : aws_vpc.my_vpc[0].cidr_block
}

output "vpc_status" {
  value = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpc.existing_vpc_details[0].state : "newly created"
}
