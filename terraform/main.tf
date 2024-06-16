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

data "aws_internet_gateway" "all_igws" {
  # No filter needed, we will filter manually
}

# Create a map of Internet Gateways attached to our target VPC
locals {
  target_vpc_id = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : null
  attached_igw = {
    for igw in data.aws_internet_gateway.all_igws : igw => igw
    if length([
      for attachment in data.aws_internet_gateway.all_igws.attachments : attachment.vpc_id
      if attachment.vpc_id == local.target_vpc_id
    ]) > 0
  }
}

resource "aws_internet_gateway" "my_igw" {
  count  = length(local.attached_igw) == 0 ? 1 : 0
  vpc_id = length(data.aws_vpcs.existing.ids) > 0 ? data.aws_vpcs.existing.ids[0] : aws_vpc.my_vpc[0].id

  tags = {
    Name = "MyInternetGateway"
  }

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
